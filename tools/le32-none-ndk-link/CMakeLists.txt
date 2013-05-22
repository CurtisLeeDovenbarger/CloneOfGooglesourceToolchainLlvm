set(LLVM_LINK_COMPONENTS
  asmparser
  archive
  bitreader
  bitwriter
  codegen
  instrumentation
  ipo
  linker
  selectiondag
  )

add_llvm_tool(le32-none-ndk-link
  AndroidBitcodeLinker.cpp
  le32-none-ndk-link.cpp
  )
