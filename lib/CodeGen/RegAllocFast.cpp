//===- RegAllocFast.cpp - A fast register allocator for debug code --------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
/// \file This register allocator allocates registers to a basic block at a
/// time, attempting to keep values in registers and reusing registers as
/// appropriate.
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/IndexedMap.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SparseSet.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegAllocRegistry.h"
#include "llvm/CodeGen/RegisterClassInfo.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Metadata.h"
#include "llvm/MC/MCInstrDesc.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/Pass.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/Target/TargetOpcodes.h"
#include "llvm/Target/TargetRegisterInfo.h"
#include "llvm/Target/TargetSubtargetInfo.h"
#include <cassert>
#include <tuple>
#include <vector>

using namespace llvm;

#define DEBUG_TYPE "regalloc"

STATISTIC(NumStores, "Number of stores added");
STATISTIC(NumLoads , "Number of loads added");
STATISTIC(NumCopies, "Number of copies coalesced");

static RegisterRegAlloc
  fastRegAlloc("fast", "fast register allocator", createFastRegisterAllocator);

namespace {

  class RegAllocFast : public MachineFunctionPass {
  public:
    static char ID;

    RegAllocFast() : MachineFunctionPass(ID), StackSlotForVirtReg(-1) {}

  private:
    MachineFrameInfo *MFI;
    MachineRegisterInfo *MRI;
    const TargetRegisterInfo *TRI;
    const TargetInstrInfo *TII;
    RegisterClassInfo RegClassInfo;

    /// Basic block currently being allocated.
    MachineBasicBlock *MBB;

    /// Maps virtual regs to the frame index where these values are spilled.
    IndexedMap<int, VirtReg2IndexFunctor> StackSlotForVirtReg;

    /// Everything we know about a live virtual register.
    struct LiveReg {
      MachineInstr *LastUse = nullptr; ///< Last instr to use reg.
      unsigned VirtReg;                ///< Virtual register number.
      MCPhysReg PhysReg = 0;           ///< Currently held here.
      unsigned short LastOpNum = 0;    ///< OpNum on LastUse.
      bool Dirty = false;              ///< Register needs spill.

      explicit LiveReg(unsigned v) : VirtReg(v) {}

      unsigned getSparseSetIndex() const {
        return TargetRegisterInfo::virtReg2Index(VirtReg);
      }
    };

    using LiveRegMap = SparseSet<LiveReg>;

    /// This map contains entries for each virtual register that is currently
    /// available in a physical register.
    LiveRegMap LiveVirtRegs;

    DenseMap<unsigned, SmallVector<MachineInstr *, 4>> LiveDbgValueMap;

    /// Track the state of a physical register.
    enum RegState {
      /// A disabled register is not available for allocation, but an alias may
      /// be in use. A register can only be moved out of the disabled state if
      /// all aliases are disabled.
      regDisabled,

      /// A free register is not currently in use and can be allocated
      /// immediately without checking aliases.
      regFree,

      /// A reserved register has been assigned explicitly (e.g., setting up a
      /// call parameter), and it remains reserved until it is used.
      regReserved

      /// A register state may also be a virtual register number, indication
      /// that the physical register is currently allocated to a virtual
      /// register. In that case, LiveVirtRegs contains the inverse mapping.
    };

    /// One of the RegState enums, or a virtreg.
    std::vector<unsigned> PhysRegState;

    SmallVector<unsigned, 16> VirtDead;
    SmallVector<MachineInstr *, 32> Coalesced;

    /// Set of register units.
    using UsedInInstrSet = SparseSet<unsigned>;

    /// Set of register units that are used in the current instruction, and so
    /// cannot be allocated.
    UsedInInstrSet UsedInInstr;

    /// Mark a physreg as used in this instruction.
    void markRegUsedInInstr(MCPhysReg PhysReg) {
      for (MCRegUnitIterator Units(PhysReg, TRI); Units.isValid(); ++Units)
        UsedInInstr.insert(*Units);
    }

    /// Check if a physreg or any of its aliases are used in this instruction.
    bool isRegUsedInInstr(MCPhysReg PhysReg) const {
      for (MCRegUnitIterator Units(PhysReg, TRI); Units.isValid(); ++Units)
        if (UsedInInstr.count(*Units))
          return true;
      return false;
    }

    /// This flag is set when LiveRegMap will be cleared completely after
    /// spilling all live registers. LiveRegMap entries should not be erased.
    bool isBulkSpilling = false;

    enum : unsigned {
      spillClean = 1,
      spillDirty = 100,
      spillImpossible = ~0u
    };

  public:
    StringRef getPassName() const override { return "Fast Register Allocator"; }

    void getAnalysisUsage(AnalysisUsage &AU) const override {
      AU.setPreservesCFG();
      MachineFunctionPass::getAnalysisUsage(AU);
    }

    MachineFunctionProperties getRequiredProperties() const override {
      return MachineFunctionProperties().set(
          MachineFunctionProperties::Property::NoPHIs);
    }

    MachineFunctionProperties getSetProperties() const override {
      return MachineFunctionProperties().set(
          MachineFunctionProperties::Property::NoVRegs);
    }

  private:
    bool runOnMachineFunction(MachineFunction &Fn) override;
    void allocateBasicBlock(MachineBasicBlock &MBB);
    void handleThroughOperands(MachineInstr &MI,
                               SmallVectorImpl<unsigned> &VirtDead);
    int getStackSpaceFor(unsigned VirtReg, const TargetRegisterClass &RC);
    bool isLastUseOfLocalReg(const MachineOperand &MO) const;

    void addKillFlag(const LiveReg &LRI);
    void killVirtReg(LiveRegMap::iterator LRI);
    void killVirtReg(unsigned VirtReg);
    void spillVirtReg(MachineBasicBlock::iterator MI, LiveRegMap::iterator);
    void spillVirtReg(MachineBasicBlock::iterator MI, unsigned VirtReg);

    void usePhysReg(MachineOperand &MO);
    void definePhysReg(MachineBasicBlock::iterator MI, MCPhysReg PhysReg,
                       RegState NewState);
    unsigned calcSpillCost(MCPhysReg PhysReg) const;
    void assignVirtToPhysReg(LiveReg &, MCPhysReg PhysReg);

    LiveRegMap::iterator findLiveVirtReg(unsigned VirtReg) {
      return LiveVirtRegs.find(TargetRegisterInfo::virtReg2Index(VirtReg));
    }

    LiveRegMap::const_iterator findLiveVirtReg(unsigned VirtReg) const {
      return LiveVirtRegs.find(TargetRegisterInfo::virtReg2Index(VirtReg));
    }

    LiveRegMap::iterator assignVirtToPhysReg(unsigned VReg, MCPhysReg PhysReg);
    LiveRegMap::iterator allocVirtReg(MachineInstr &MI, LiveRegMap::iterator,
                                      unsigned Hint);
    LiveRegMap::iterator defineVirtReg(MachineInstr &MI, unsigned OpNum,
                                       unsigned VirtReg, unsigned Hint);
    LiveRegMap::iterator reloadVirtReg(MachineInstr &MI, unsigned OpNum,
                                       unsigned VirtReg, unsigned Hint);
    void spillAll(MachineBasicBlock::iterator MI);
    bool setPhysReg(MachineInstr &MI, unsigned OpNum, MCPhysReg PhysReg);

    void dumpState();
  };

} // end anonymous namespace

char RegAllocFast::ID = 0;

INITIALIZE_PASS(RegAllocFast, "regallocfast", "Fast Register Allocator", false,
                false)

/// This allocates space for the specified virtual register to be held on the
/// stack.
int RegAllocFast::getStackSpaceFor(unsigned VirtReg,
                                   const TargetRegisterClass &RC) {
  // Find the location Reg would belong...
  int SS = StackSlotForVirtReg[VirtReg];
  // Already has space allocated?
  if (SS != -1)
    return SS;

  // Allocate a new stack object for this spill location...
  unsigned Size = TRI->getSpillSize(RC);
  unsigned Align = TRI->getSpillAlignment(RC);
  int FrameIdx = MFI->CreateSpillStackObject(Size, Align);

  // Assign the slot.
  StackSlotForVirtReg[VirtReg] = FrameIdx;
  return FrameIdx;
}

/// Return true if MO is the only remaining reference to its virtual register,
/// and it is guaranteed to be a block-local register.
bool RegAllocFast::isLastUseOfLocalReg(const MachineOperand &MO) const {
  // If the register has ever been spilled or reloaded, we conservatively assume
  // it is a global register used in multiple blocks.
  if (StackSlotForVirtReg[MO.getReg()] != -1)
    return false;

  // Check that the use/def chain has exactly one operand - MO.
  MachineRegisterInfo::reg_nodbg_iterator I = MRI->reg_nodbg_begin(MO.getReg());
  if (&*I != &MO)
    return false;
  return ++I == MRI->reg_nodbg_end();
}

/// Set kill flags on last use of a virtual register.
void RegAllocFast::addKillFlag(const LiveReg &LR) {
  if (!LR.LastUse) return;
  MachineOperand &MO = LR.LastUse->getOperand(LR.LastOpNum);
  if (MO.isUse() && !LR.LastUse->isRegTiedToDefOperand(LR.LastOpNum)) {
    if (MO.getReg() == LR.PhysReg)
      MO.setIsKill();
    // else, don't do anything we are problably redefining a
    // subreg of this register and given we don't track which
    // lanes are actually dead, we cannot insert a kill flag here.
    // Otherwise we may end up in a situation like this:
    // ... = (MO) physreg:sub1, physreg <implicit-use, kill>
    // ... <== Here we would allow later pass to reuse physreg:sub1
    //         which is potentially wrong.
    // LR:sub0 = ...
    // ... = LR.sub1 <== This is going to use physreg:sub1
  }
}

/// Mark virtreg as no longer available.
void RegAllocFast::killVirtReg(LiveRegMap::iterator LRI) {
  addKillFlag(*LRI);
  assert(PhysRegState[LRI->PhysReg] == LRI->VirtReg &&
         "Broken RegState mapping");
  PhysRegState[LRI->PhysReg] = regFree;
  // Erase from LiveVirtRegs unless we're spilling in bulk.
  if (!isBulkSpilling)
    LiveVirtRegs.erase(LRI);
}

/// Mark virtreg as no longer available.
void RegAllocFast::killVirtReg(unsigned VirtReg) {
  assert(TargetRegisterInfo::isVirtualRegister(VirtReg) &&
         "killVirtReg needs a virtual register");
  LiveRegMap::iterator LRI = findLiveVirtReg(VirtReg);
  if (LRI != LiveVirtRegs.end())
    killVirtReg(LRI);
}

/// This method spills the value specified by VirtReg into the corresponding
/// stack slot if needed.
void RegAllocFast::spillVirtReg(MachineBasicBlock::iterator MI,
                                unsigned VirtReg) {
  assert(TargetRegisterInfo::isVirtualRegister(VirtReg) &&
         "Spilling a physical register is illegal!");
  LiveRegMap::iterator LRI = findLiveVirtReg(VirtReg);
  assert(LRI != LiveVirtRegs.end() && "Spilling unmapped virtual register");
  spillVirtReg(MI, LRI);
}

/// Do the actual work of spilling.
void RegAllocFast::spillVirtReg(MachineBasicBlock::iterator MI,
                                LiveRegMap::iterator LRI) {
  LiveReg &LR = *LRI;
  assert(PhysRegState[LR.PhysReg] == LRI->VirtReg && "Broken RegState mapping");

  if (LR.Dirty) {
    // If this physreg is used by the instruction, we want to kill it on the
    // instruction, not on the spill.
    bool SpillKill = MachineBasicBlock::iterator(LR.LastUse) != MI;
    LR.Dirty = false;
    DEBUG(dbgs() << "Spilling " << PrintReg(LRI->VirtReg, TRI)
                 << " in " << PrintReg(LR.PhysReg, TRI));
    const TargetRegisterClass &RC = *MRI->getRegClass(LRI->VirtReg);
    int FI = getStackSpaceFor(LRI->VirtReg, RC);
    DEBUG(dbgs() << " to stack slot #" << FI << "\n");
    TII->storeRegToStackSlot(*MBB, MI, LR.PhysReg, SpillKill, FI, &RC, TRI);
    ++NumStores;   // Update statistics

    // If this register is used by DBG_VALUE then insert new DBG_VALUE to
    // identify spilled location as the place to find corresponding variable's
    // value.
    SmallVectorImpl<MachineInstr *> &LRIDbgValues =
      LiveDbgValueMap[LRI->VirtReg];
    for (MachineInstr *DBG : LRIDbgValues) {
      MachineInstr *NewDV = buildDbgValueForSpill(*MBB, MI, *DBG, FI);
      assert(NewDV->getParent() == MBB && "dangling parent pointer");
      (void)NewDV;
      DEBUG(dbgs() << "Inserting debug info due to spill:" << "\n" << *NewDV);
    }
    // Now this register is spilled there is should not be any DBG_VALUE
    // pointing to this register because they are all pointing to spilled value
    // now.
    LRIDbgValues.clear();
    if (SpillKill)
      LR.LastUse = nullptr; // Don't kill register again
  }
  killVirtReg(LRI);
}

/// Spill all dirty virtregs without killing them.
void RegAllocFast::spillAll(MachineBasicBlock::iterator MI) {
  if (LiveVirtRegs.empty()) return;
  isBulkSpilling = true;
  // The LiveRegMap is keyed by an unsigned (the virtreg number), so the order
  // of spilling here is deterministic, if arbitrary.
  for (LiveRegMap::iterator I = LiveVirtRegs.begin(), E = LiveVirtRegs.end();
       I != E; ++I)
    spillVirtReg(MI, I);
  LiveVirtRegs.clear();
  isBulkSpilling = false;
}

/// Handle the direct use of a physical register.  Check that the register is
/// not used by a virtreg. Kill the physreg, marking it free. This may add
/// implicit kills to MO->getParent() and invalidate MO.
void RegAllocFast::usePhysReg(MachineOperand &MO) {
  // Ignore undef uses.
  if (MO.isUndef())
    return;

  unsigned PhysReg = MO.getReg();
  assert(TargetRegisterInfo::isPhysicalRegister(PhysReg) &&
         "Bad usePhysReg operand");

  markRegUsedInInstr(PhysReg);
  switch (PhysRegState[PhysReg]) {
  case regDisabled:
    break;
  case regReserved:
    PhysRegState[PhysReg] = regFree;
    LLVM_FALLTHROUGH;
  case regFree:
    MO.setIsKill();
    return;
  default:
    // The physreg was allocated to a virtual register. That means the value we
    // wanted has been clobbered.
    llvm_unreachable("Instruction uses an allocated register");
  }

  // Maybe a superregister is reserved?
  for (MCRegAliasIterator AI(PhysReg, TRI, false); AI.isValid(); ++AI) {
    MCPhysReg Alias = *AI;
    switch (PhysRegState[Alias]) {
    case regDisabled:
      break;
    case regReserved:
      // Either PhysReg is a subregister of Alias and we mark the
      // whole register as free, or PhysReg is the superregister of
      // Alias and we mark all the aliases as disabled before freeing
      // PhysReg.
      // In the latter case, since PhysReg was disabled, this means that
      // its value is defined only by physical sub-registers. This check
      // is performed by the assert of the default case in this loop.
      // Note: The value of the superregister may only be partial
      // defined, that is why regDisabled is a valid state for aliases.
      assert((TRI->isSuperRegister(PhysReg, Alias) ||
              TRI->isSuperRegister(Alias, PhysReg)) &&
             "Instruction is not using a subregister of a reserved register");
      LLVM_FALLTHROUGH;
    case regFree:
      if (TRI->isSuperRegister(PhysReg, Alias)) {
        // Leave the superregister in the working set.
        PhysRegState[Alias] = regFree;
        MO.getParent()->addRegisterKilled(Alias, TRI, true);
        return;
      }
      // Some other alias was in the working set - clear it.
      PhysRegState[Alias] = regDisabled;
      break;
    default:
      llvm_unreachable("Instruction uses an alias of an allocated register");
    }
  }

  // All aliases are disabled, bring register into working set.
  PhysRegState[PhysReg] = regFree;
  MO.setIsKill();
}

/// Mark PhysReg as reserved or free after spilling any virtregs. This is very
/// similar to defineVirtReg except the physreg is reserved instead of
/// allocated.
void RegAllocFast::definePhysReg(MachineBasicBlock::iterator MI,
                                 MCPhysReg PhysReg, RegState NewState) {
  markRegUsedInInstr(PhysReg);
  switch (unsigned VirtReg = PhysRegState[PhysReg]) {
  case regDisabled:
    break;
  default:
    spillVirtReg(MI, VirtReg);
    LLVM_FALLTHROUGH;
  case regFree:
  case regReserved:
    PhysRegState[PhysReg] = NewState;
    return;
  }

  // This is a disabled register, disable all aliases.
  PhysRegState[PhysReg] = NewState;
  for (MCRegAliasIterator AI(PhysReg, TRI, false); AI.isValid(); ++AI) {
    MCPhysReg Alias = *AI;
    switch (unsigned VirtReg = PhysRegState[Alias]) {
    case regDisabled:
      break;
    default:
      spillVirtReg(MI, VirtReg);
      LLVM_FALLTHROUGH;
    case regFree:
    case regReserved:
      PhysRegState[Alias] = regDisabled;
      if (TRI->isSuperRegister(PhysReg, Alias))
        return;
      break;
    }
  }
}

/// \brief Return the cost of spilling clearing out PhysReg and aliases so it is
/// free for allocation. Returns 0 when PhysReg is free or disabled with all
/// aliases disabled - it can be allocated directly.
/// \returns spillImpossible when PhysReg or an alias can't be spilled.
unsigned RegAllocFast::calcSpillCost(MCPhysReg PhysReg) const {
  if (isRegUsedInInstr(PhysReg)) {
    DEBUG(dbgs() << PrintReg(PhysReg, TRI) << " is already used in instr.\n");
    return spillImpossible;
  }
  switch (unsigned VirtReg = PhysRegState[PhysReg]) {
  case regDisabled:
    break;
  case regFree:
    return 0;
  case regReserved:
    DEBUG(dbgs() << PrintReg(VirtReg, TRI) << " corresponding "
                 << PrintReg(PhysReg, TRI) << " is reserved already.\n");
    return spillImpossible;
  default: {
    LiveRegMap::const_iterator I = findLiveVirtReg(VirtReg);
    assert(I != LiveVirtRegs.end() && "Missing VirtReg entry");
    return I->Dirty ? spillDirty : spillClean;
  }
  }

  // This is a disabled register, add up cost of aliases.
  DEBUG(dbgs() << PrintReg(PhysReg, TRI) << " is disabled.\n");
  unsigned Cost = 0;
  for (MCRegAliasIterator AI(PhysReg, TRI, false); AI.isValid(); ++AI) {
    MCPhysReg Alias = *AI;
    switch (unsigned VirtReg = PhysRegState[Alias]) {
    case regDisabled:
      break;
    case regFree:
      ++Cost;
      break;
    case regReserved:
      return spillImpossible;
    default: {
      LiveRegMap::const_iterator I = findLiveVirtReg(VirtReg);
      assert(I != LiveVirtRegs.end() && "Missing VirtReg entry");
      Cost += I->Dirty ? spillDirty : spillClean;
      break;
    }
    }
  }
  return Cost;
}

/// \brief This method updates local state so that we know that PhysReg is the
/// proper container for VirtReg now.  The physical register must not be used
/// for anything else when this is called.
void RegAllocFast::assignVirtToPhysReg(LiveReg &LR, MCPhysReg PhysReg) {
  DEBUG(dbgs() << "Assigning " << PrintReg(LR.VirtReg, TRI) << " to "
               << PrintReg(PhysReg, TRI) << "\n");
  PhysRegState[PhysReg] = LR.VirtReg;
  assert(!LR.PhysReg && "Already assigned a physreg");
  LR.PhysReg = PhysReg;
}

RegAllocFast::LiveRegMap::iterator
RegAllocFast::assignVirtToPhysReg(unsigned VirtReg, MCPhysReg PhysReg) {
  LiveRegMap::iterator LRI = findLiveVirtReg(VirtReg);
  assert(LRI != LiveVirtRegs.end() && "VirtReg disappeared");
  assignVirtToPhysReg(*LRI, PhysReg);
  return LRI;
}

/// Allocates a physical register for VirtReg.
RegAllocFast::LiveRegMap::iterator RegAllocFast::allocVirtReg(MachineInstr &MI,
    LiveRegMap::iterator LRI, unsigned Hint) {
  const unsigned VirtReg = LRI->VirtReg;

  assert(TargetRegisterInfo::isVirtualRegister(VirtReg) &&
         "Can only allocate virtual registers");

  // Take hint when possible.
  const TargetRegisterClass &RC = *MRI->getRegClass(VirtReg);
  if (TargetRegisterInfo::isPhysicalRegister(Hint) &&
      MRI->isAllocatable(Hint) && RC.contains(Hint)) {
    // Ignore the hint if we would have to spill a dirty register.
    unsigned Cost = calcSpillCost(Hint);
    if (Cost < spillDirty) {
      if (Cost)
        definePhysReg(MI, Hint, regFree);
      // definePhysReg may kill virtual registers and modify LiveVirtRegs.
      // That invalidates LRI, so run a new lookup for VirtReg.
      return assignVirtToPhysReg(VirtReg, Hint);
    }
  }

  // First try to find a completely free register.
  ArrayRef<MCPhysReg> AO = RegClassInfo.getOrder(&RC);
  for (MCPhysReg PhysReg : AO) {
    if (PhysRegState[PhysReg] == regFree && !isRegUsedInInstr(PhysReg)) {
      assignVirtToPhysReg(*LRI, PhysReg);
      return LRI;
    }
  }

  DEBUG(dbgs() << "Allocating " << PrintReg(VirtReg) << " from "
               << TRI->getRegClassName(&RC) << "\n");

  unsigned BestReg = 0;
  unsigned BestCost = spillImpossible;
  for (MCPhysReg PhysReg : AO) {
    unsigned Cost = calcSpillCost(PhysReg);
    DEBUG(dbgs() << "\tRegister: " << PrintReg(PhysReg, TRI) << "\n");
    DEBUG(dbgs() << "\tCost: " << Cost << "\n");
    DEBUG(dbgs() << "\tBestCost: " << BestCost << "\n");
    // Cost is 0 when all aliases are already disabled.
    if (Cost == 0) {
      assignVirtToPhysReg(*LRI, PhysReg);
      return LRI;
    }
    if (Cost < BestCost)
      BestReg = PhysReg, BestCost = Cost;
  }

  if (BestReg) {
    definePhysReg(MI, BestReg, regFree);
    // definePhysReg may kill virtual registers and modify LiveVirtRegs.
    // That invalidates LRI, so run a new lookup for VirtReg.
    return assignVirtToPhysReg(VirtReg, BestReg);
  }

  // Nothing we can do. Report an error and keep going with a bad allocation.
  if (MI.isInlineAsm())
    MI.emitError("inline assembly requires more registers than available");
  else
    MI.emitError("ran out of registers during register allocation");
  definePhysReg(MI, *AO.begin(), regFree);
  return assignVirtToPhysReg(VirtReg, *AO.begin());
}

/// Allocates a register for VirtReg and mark it as dirty.
RegAllocFast::LiveRegMap::iterator RegAllocFast::defineVirtReg(MachineInstr &MI,
                                                               unsigned OpNum,
                                                               unsigned VirtReg,
                                                               unsigned Hint) {
  assert(TargetRegisterInfo::isVirtualRegister(VirtReg) &&
         "Not a virtual register");
  LiveRegMap::iterator LRI;
  bool New;
  std::tie(LRI, New) = LiveVirtRegs.insert(LiveReg(VirtReg));
  if (New) {
    // If there is no hint, peek at the only use of this register.
    if ((!Hint || !TargetRegisterInfo::isPhysicalRegister(Hint)) &&
        MRI->hasOneNonDBGUse(VirtReg)) {
      const MachineInstr &UseMI = *MRI->use_instr_nodbg_begin(VirtReg);
      // It's a copy, use the destination register as a hint.
      if (UseMI.isCopyLike())
        Hint = UseMI.getOperand(0).getReg();
    }
    LRI = allocVirtReg(MI, LRI, Hint);
  } else if (LRI->LastUse) {
    // Redefining a live register - kill at the last use, unless it is this
    // instruction defining VirtReg multiple times.
    if (LRI->LastUse != &MI || LRI->LastUse->getOperand(LRI->LastOpNum).isUse())
      addKillFlag(*LRI);
  }
  assert(LRI->PhysReg && "Register not assigned");
  LRI->LastUse = &MI;
  LRI->LastOpNum = OpNum;
  LRI->Dirty = true;
  markRegUsedInInstr(LRI->PhysReg);
  return LRI;
}

/// Make sure VirtReg is available in a physreg and return it.
RegAllocFast::LiveRegMap::iterator RegAllocFast::reloadVirtReg(MachineInstr &MI,
                                                               unsigned OpNum,
                                                               unsigned VirtReg,
                                                               unsigned Hint) {
  assert(TargetRegisterInfo::isVirtualRegister(VirtReg) &&
         "Not a virtual register");
  LiveRegMap::iterator LRI;
  bool New;
  std::tie(LRI, New) = LiveVirtRegs.insert(LiveReg(VirtReg));
  MachineOperand &MO = MI.getOperand(OpNum);
  if (New) {
    LRI = allocVirtReg(MI, LRI, Hint);
    const TargetRegisterClass &RC = *MRI->getRegClass(VirtReg);
    int FrameIndex = getStackSpaceFor(VirtReg, RC);
    DEBUG(dbgs() << "Reloading " << PrintReg(VirtReg, TRI) << " into "
                 << PrintReg(LRI->PhysReg, TRI) << "\n");
    TII->loadRegFromStackSlot(*MBB, MI, LRI->PhysReg, FrameIndex, &RC, TRI);
    ++NumLoads;
  } else if (LRI->Dirty) {
    if (isLastUseOfLocalReg(MO)) {
      DEBUG(dbgs() << "Killing last use: " << MO << "\n");
      if (MO.isUse())
        MO.setIsKill();
      else
        MO.setIsDead();
    } else if (MO.isKill()) {
      DEBUG(dbgs() << "Clearing dubious kill: " << MO << "\n");
      MO.setIsKill(false);
    } else if (MO.isDead()) {
      DEBUG(dbgs() << "Clearing dubious dead: " << MO << "\n");
      MO.setIsDead(false);
    }
  } else if (MO.isKill()) {
    // We must remove kill flags from uses of reloaded registers because the
    // register would be killed immediately, and there might be a second use:
    //   %foo = OR %x<kill>, %x
    // This would cause a second reload of %x into a different register.
    DEBUG(dbgs() << "Clearing clean kill: " << MO << "\n");
    MO.setIsKill(false);
  } else if (MO.isDead()) {
    DEBUG(dbgs() << "Clearing clean dead: " << MO << "\n");
    MO.setIsDead(false);
  }
  assert(LRI->PhysReg && "Register not assigned");
  LRI->LastUse = &MI;
  LRI->LastOpNum = OpNum;
  markRegUsedInInstr(LRI->PhysReg);
  return LRI;
}

/// Changes operand OpNum in MI the refer the PhysReg, considering subregs. This
/// may invalidate any operand pointers.  Return true if the operand kills its
/// register.
bool RegAllocFast::setPhysReg(MachineInstr &MI, unsigned OpNum,
                              MCPhysReg PhysReg) {
  MachineOperand &MO = MI.getOperand(OpNum);
  bool Dead = MO.isDead();
  if (!MO.getSubReg()) {
    MO.setReg(PhysReg);
    return MO.isKill() || Dead;
  }

  // Handle subregister index.
  MO.setReg(PhysReg ? TRI->getSubReg(PhysReg, MO.getSubReg()) : 0);
  MO.setSubReg(0);

  // A kill flag implies killing the full register. Add corresponding super
  // register kill.
  if (MO.isKill()) {
    MI.addRegisterKilled(PhysReg, TRI, true);
    return true;
  }

  // A <def,read-undef> of a sub-register requires an implicit def of the full
  // register.
  if (MO.isDef() && MO.isUndef())
    MI.addRegisterDefined(PhysReg, TRI);

  return Dead;
}

// Handles special instruction operand like early clobbers and tied ops when
// there are additional physreg defines.
void RegAllocFast::handleThroughOperands(MachineInstr &MI,
                                         SmallVectorImpl<unsigned> &VirtDead) {
  DEBUG(dbgs() << "Scanning for through registers:");
  SmallSet<unsigned, 8> ThroughRegs;
  for (const MachineOperand &MO : MI.operands()) {
    if (!MO.isReg()) continue;
    unsigned Reg = MO.getReg();
    if (!TargetRegisterInfo::isVirtualRegister(Reg))
      continue;
    if (MO.isEarlyClobber() || (MO.isUse() && MO.isTied()) ||
        (MO.getSubReg() && MI.readsVirtualRegister(Reg))) {
      if (ThroughRegs.insert(Reg).second)
        DEBUG(dbgs() << ' ' << PrintReg(Reg));
    }
  }

  // If any physreg defines collide with preallocated through registers,
  // we must spill and reallocate.
  DEBUG(dbgs() << "\nChecking for physdef collisions.\n");
  for (const MachineOperand &MO : MI.operands()) {
    if (!MO.isReg() || !MO.isDef()) continue;
    unsigned Reg = MO.getReg();
    if (!Reg || !TargetRegisterInfo::isPhysicalRegister(Reg)) continue;
    markRegUsedInInstr(Reg);
    for (MCRegAliasIterator AI(Reg, TRI, true); AI.isValid(); ++AI) {
      if (ThroughRegs.count(PhysRegState[*AI]))
        definePhysReg(MI, *AI, regFree);
    }
  }

  SmallVector<unsigned, 8> PartialDefs;
  DEBUG(dbgs() << "Allocating tied uses.\n");
  for (unsigned I = 0, E = MI.getNumOperands(); I != E; ++I) {
    const MachineOperand &MO = MI.getOperand(I);
    if (!MO.isReg()) continue;
    unsigned Reg = MO.getReg();
    if (!TargetRegisterInfo::isVirtualRegister(Reg)) continue;
    if (MO.isUse()) {
      if (!MO.isTied()) continue;
      DEBUG(dbgs() << "Operand " << I << "("<< MO << ") is tied to operand "
        << MI.findTiedOperandIdx(I) << ".\n");
      LiveRegMap::iterator LRI = reloadVirtReg(MI, I, Reg, 0);
      MCPhysReg PhysReg = LRI->PhysReg;
      setPhysReg(MI, I, PhysReg);
      // Note: we don't update the def operand yet. That would cause the normal
      // def-scan to attempt spilling.
    } else if (MO.getSubReg() && MI.readsVirtualRegister(Reg)) {
      DEBUG(dbgs() << "Partial redefine: " << MO << "\n");
      // Reload the register, but don't assign to the operand just yet.
      // That would confuse the later phys-def processing pass.
      LiveRegMap::iterator LRI = reloadVirtReg(MI, I, Reg, 0);
      PartialDefs.push_back(LRI->PhysReg);
    }
  }

  DEBUG(dbgs() << "Allocating early clobbers.\n");
  for (unsigned I = 0, E = MI.getNumOperands(); I != E; ++I) {
    const MachineOperand &MO = MI.getOperand(I);
    if (!MO.isReg()) continue;
    unsigned Reg = MO.getReg();
    if (!TargetRegisterInfo::isVirtualRegister(Reg)) continue;
    if (!MO.isEarlyClobber())
      continue;
    // Note: defineVirtReg may invalidate MO.
    LiveRegMap::iterator LRI = defineVirtReg(MI, I, Reg, 0);
    MCPhysReg PhysReg = LRI->PhysReg;
    if (setPhysReg(MI, I, PhysReg))
      VirtDead.push_back(Reg);
  }

  // Restore UsedInInstr to a state usable for allocating normal virtual uses.
  UsedInInstr.clear();
  for (const MachineOperand &MO : MI.operands()) {
    if (!MO.isReg() || (MO.isDef() && !MO.isEarlyClobber())) continue;
    unsigned Reg = MO.getReg();
    if (!Reg || !TargetRegisterInfo::isPhysicalRegister(Reg)) continue;
    DEBUG(dbgs() << "\tSetting " << PrintReg(Reg, TRI)
                 << " as used in instr\n");
    markRegUsedInInstr(Reg);
  }

  // Also mark PartialDefs as used to avoid reallocation.
  for (unsigned PartialDef : PartialDefs)
    markRegUsedInInstr(PartialDef);
}

#ifndef NDEBUG
void RegAllocFast::dumpState() {
  for (unsigned Reg = 1, E = TRI->getNumRegs(); Reg != E; ++Reg) {
    if (PhysRegState[Reg] == regDisabled) continue;
    dbgs() << " " << TRI->getName(Reg);
    switch(PhysRegState[Reg]) {
    case regFree:
      break;
    case regReserved:
      dbgs() << "*";
      break;
    default: {
      dbgs() << '=' << PrintReg(PhysRegState[Reg]);
      LiveRegMap::iterator I = findLiveVirtReg(PhysRegState[Reg]);
      assert(I != LiveVirtRegs.end() && "Missing VirtReg entry");
      if (I->Dirty)
        dbgs() << "*";
      assert(I->PhysReg == Reg && "Bad inverse map");
      break;
    }
    }
  }
  dbgs() << '\n';
  // Check that LiveVirtRegs is the inverse.
  for (LiveRegMap::iterator i = LiveVirtRegs.begin(),
       e = LiveVirtRegs.end(); i != e; ++i) {
    assert(TargetRegisterInfo::isVirtualRegister(i->VirtReg) &&
           "Bad map key");
    assert(TargetRegisterInfo::isPhysicalRegister(i->PhysReg) &&
           "Bad map value");
    assert(PhysRegState[i->PhysReg] == i->VirtReg && "Bad inverse map");
  }
}
#endif

void RegAllocFast::allocateBasicBlock(MachineBasicBlock &MBB) {
  this->MBB = &MBB;
  DEBUG(dbgs() << "\nAllocating " << MBB);

  PhysRegState.assign(TRI->getNumRegs(), regDisabled);
  assert(LiveVirtRegs.empty() && "Mapping not cleared from last block?");

  MachineBasicBlock::iterator MII = MBB.begin();

  // Add live-in registers as live.
  for (const MachineBasicBlock::RegisterMaskPair LI : MBB.liveins())
    if (MRI->isAllocatable(LI.PhysReg))
      definePhysReg(MII, LI.PhysReg, regReserved);

  VirtDead.clear();
  Coalesced.clear();

  // Otherwise, sequentially allocate each instruction in the MBB.
  for (MachineInstr &MI : MBB) {
    const MCInstrDesc &MCID = MI.getDesc();
    DEBUG(
      dbgs() << "\n>> " << MI << "Regs:";
      dumpState()
    );

    // Debug values are not allowed to change codegen in any way.
    if (MI.isDebugValue()) {
      MachineInstr *DebugMI = &MI;
      MachineOperand &MO = DebugMI->getOperand(0);

      // Ignore DBG_VALUEs that aren't based on virtual registers. These are
      // mostly constants and frame indices.
      if (!MO.isReg())
        continue;
      unsigned Reg = MO.getReg();
      if (!TargetRegisterInfo::isVirtualRegister(Reg))
        continue;

      // See if this virtual register has already been allocated to a physical
      // register or spilled to a stack slot.
      LiveRegMap::iterator LRI = findLiveVirtReg(Reg);
      if (LRI != LiveVirtRegs.end())
        setPhysReg(*DebugMI, 0, LRI->PhysReg);
      else {
        int SS = StackSlotForVirtReg[Reg];
        if (SS != -1) {
          // Modify DBG_VALUE now that the value is in a spill slot.
          updateDbgValueForSpill(*DebugMI, SS);
          DEBUG(dbgs() << "Modifying debug info due to spill:"
                       << "\t" << *DebugMI);
          continue;
        }

        // We can't allocate a physreg for a DebugValue, sorry!
        DEBUG(dbgs() << "Unable to allocate vreg used by DBG_VALUE");
        MO.setReg(0);
      }

      // If Reg hasn't been spilled, put this DBG_VALUE in LiveDbgValueMap so
      // that future spills of Reg will have DBG_VALUEs.
      LiveDbgValueMap[Reg].push_back(DebugMI);
      continue;
    }

    // If this is a copy, we may be able to coalesce.
    unsigned CopySrcReg = 0;
    unsigned CopyDstReg = 0;
    unsigned CopySrcSub = 0;
    unsigned CopyDstSub = 0;
    if (MI.isCopy()) {
      CopyDstReg = MI.getOperand(0).getReg();
      CopySrcReg = MI.getOperand(1).getReg();
      CopyDstSub = MI.getOperand(0).getSubReg();
      CopySrcSub = MI.getOperand(1).getSubReg();
    }

    // Track registers used by instruction.
    UsedInInstr.clear();

    // First scan.
    // Mark physreg uses and early clobbers as used.
    // Find the end of the virtreg operands
    unsigned VirtOpEnd = 0;
    bool hasTiedOps = false;
    bool hasEarlyClobbers = false;
    bool hasPartialRedefs = false;
    bool hasPhysDefs = false;
    for (unsigned i = 0, e = MI.getNumOperands(); i != e; ++i) {
      MachineOperand &MO = MI.getOperand(i);
      // Make sure MRI knows about registers clobbered by regmasks.
      if (MO.isRegMask()) {
        MRI->addPhysRegsUsedFromRegMask(MO.getRegMask());
        continue;
      }
      if (!MO.isReg()) continue;
      unsigned Reg = MO.getReg();
      if (!Reg) continue;
      if (TargetRegisterInfo::isVirtualRegister(Reg)) {
        VirtOpEnd = i+1;
        if (MO.isUse()) {
          hasTiedOps = hasTiedOps ||
                              MCID.getOperandConstraint(i, MCOI::TIED_TO) != -1;
        } else {
          if (MO.isEarlyClobber())
            hasEarlyClobbers = true;
          if (MO.getSubReg() && MI.readsVirtualRegister(Reg))
            hasPartialRedefs = true;
        }
        continue;
      }
      if (!MRI->isAllocatable(Reg)) continue;
      if (MO.isUse()) {
        usePhysReg(MO);
      } else if (MO.isEarlyClobber()) {
        definePhysReg(MI, Reg,
                      (MO.isImplicit() || MO.isDead()) ? regFree : regReserved);
        hasEarlyClobbers = true;
      } else
        hasPhysDefs = true;
    }

    // The instruction may have virtual register operands that must be allocated
    // the same register at use-time and def-time: early clobbers and tied
    // operands. If there are also physical defs, these registers must avoid
    // both physical defs and uses, making them more constrained than normal
    // operands.
    // Similarly, if there are multiple defs and tied operands, we must make
    // sure the same register is allocated to uses and defs.
    // We didn't detect inline asm tied operands above, so just make this extra
    // pass for all inline asm.
    if (MI.isInlineAsm() || hasEarlyClobbers || hasPartialRedefs ||
        (hasTiedOps && (hasPhysDefs || MCID.getNumDefs() > 1))) {
      handleThroughOperands(MI, VirtDead);
      // Don't attempt coalescing when we have funny stuff going on.
      CopyDstReg = 0;
      // Pretend we have early clobbers so the use operands get marked below.
      // This is not necessary for the common case of a single tied use.
      hasEarlyClobbers = true;
    }

    // Second scan.
    // Allocate virtreg uses.
    for (unsigned I = 0; I != VirtOpEnd; ++I) {
      const MachineOperand &MO = MI.getOperand(I);
      if (!MO.isReg()) continue;
      unsigned Reg = MO.getReg();
      if (!TargetRegisterInfo::isVirtualRegister(Reg)) continue;
      if (MO.isUse()) {
        LiveRegMap::iterator LRI = reloadVirtReg(MI, I, Reg, CopyDstReg);
        MCPhysReg PhysReg = LRI->PhysReg;
        CopySrcReg = (CopySrcReg == Reg || CopySrcReg == PhysReg) ? PhysReg : 0;
        if (setPhysReg(MI, I, PhysReg))
          killVirtReg(LRI);
      }
    }

    // Track registers defined by instruction - early clobbers and tied uses at
    // this point.
    UsedInInstr.clear();
    if (hasEarlyClobbers) {
      for (const MachineOperand &MO : MI.operands()) {
        if (!MO.isReg()) continue;
        unsigned Reg = MO.getReg();
        if (!Reg || !TargetRegisterInfo::isPhysicalRegister(Reg)) continue;
        // Look for physreg defs and tied uses.
        if (!MO.isDef() && !MO.isTied()) continue;
        markRegUsedInInstr(Reg);
      }
    }

    unsigned DefOpEnd = MI.getNumOperands();
    if (MI.isCall()) {
      // Spill all virtregs before a call. This serves one purpose: If an
      // exception is thrown, the landing pad is going to expect to find
      // registers in their spill slots.
      // Note: although this is appealing to just consider all definitions
      // as call-clobbered, this is not correct because some of those
      // definitions may be used later on and we do not want to reuse
      // those for virtual registers in between.
      DEBUG(dbgs() << "  Spilling remaining registers before call.\n");
      spillAll(MI);
    }

    // Third scan.
    // Allocate defs and collect dead defs.
    for (unsigned I = 0; I != DefOpEnd; ++I) {
      const MachineOperand &MO = MI.getOperand(I);
      if (!MO.isReg() || !MO.isDef() || !MO.getReg() || MO.isEarlyClobber())
        continue;
      unsigned Reg = MO.getReg();

      if (TargetRegisterInfo::isPhysicalRegister(Reg)) {
        if (!MRI->isAllocatable(Reg)) continue;
        definePhysReg(MI, Reg, MO.isDead() ? regFree : regReserved);
        continue;
      }
      LiveRegMap::iterator LRI = defineVirtReg(MI, I, Reg, CopySrcReg);
      MCPhysReg PhysReg = LRI->PhysReg;
      if (setPhysReg(MI, I, PhysReg)) {
        VirtDead.push_back(Reg);
        CopyDstReg = 0; // cancel coalescing;
      } else
        CopyDstReg = (CopyDstReg == Reg || CopyDstReg == PhysReg) ? PhysReg : 0;
    }

    // Kill dead defs after the scan to ensure that multiple defs of the same
    // register are allocated identically. We didn't need to do this for uses
    // because we are crerating our own kill flags, and they are always at the
    // last use.
    for (unsigned VirtReg : VirtDead)
      killVirtReg(VirtReg);
    VirtDead.clear();

    if (CopyDstReg && CopyDstReg == CopySrcReg && CopyDstSub == CopySrcSub) {
      DEBUG(dbgs() << "-- coalescing: " << MI);
      Coalesced.push_back(&MI);
    } else {
      DEBUG(dbgs() << "<< " << MI);
    }
  }

  // Spill all physical registers holding virtual registers now.
  DEBUG(dbgs() << "Spilling live registers at end of block.\n");
  spillAll(MBB.getFirstTerminator());

  // Erase all the coalesced copies. We are delaying it until now because
  // LiveVirtRegs might refer to the instrs.
  for (MachineInstr *MI : Coalesced)
    MBB.erase(MI);
  NumCopies += Coalesced.size();

  DEBUG(MBB.dump());
}

/// Allocates registers for a function.
bool RegAllocFast::runOnMachineFunction(MachineFunction &MF) {
  DEBUG(dbgs() << "********** FAST REGISTER ALLOCATION **********\n"
               << "********** Function: " << MF.getName() << '\n');
  MRI = &MF.getRegInfo();
  const TargetSubtargetInfo &STI = MF.getSubtarget();
  TRI = STI.getRegisterInfo();
  TII = STI.getInstrInfo();
  MFI = &MF.getFrameInfo();
  MRI->freezeReservedRegs(MF);
  RegClassInfo.runOnMachineFunction(MF);
  UsedInInstr.clear();
  UsedInInstr.setUniverse(TRI->getNumRegUnits());

  // initialize the virtual->physical register map to have a 'null'
  // mapping for all virtual registers
  unsigned NumVirtRegs = MRI->getNumVirtRegs();
  StackSlotForVirtReg.resize(NumVirtRegs);
  LiveVirtRegs.setUniverse(NumVirtRegs);

  // Loop over all of the basic blocks, eliminating virtual register references
  for (MachineBasicBlock &MBB : MF)
    allocateBasicBlock(MBB);

  // All machine operands and other references to virtual registers have been
  // replaced. Remove the virtual registers.
  MRI->clearVirtRegs();

  StackSlotForVirtReg.clear();
  LiveDbgValueMap.clear();
  return true;
}

FunctionPass *llvm::createFastRegisterAllocator() {
  return new RegAllocFast();
}
