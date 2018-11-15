; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown-unknown -mattr=+mmx,+sse2 | FileCheck -check-prefix=X32 %s
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+mmx,+sse2 | FileCheck -check-prefix=X64 %s

;; A basic sanity check to make sure that MMX arithmetic actually compiles.
;; First is a straight translation of the original with bitcasts as needed.

define void @test0(x86_mmx* %A, x86_mmx* %B) {
; X32-LABEL: test0:
; X32:       # %bb.0: # %entry
; X32-NEXT:    pushl %ebp
; X32-NEXT:    .cfi_def_cfa_offset 8
; X32-NEXT:    .cfi_offset %ebp, -8
; X32-NEXT:    movl %esp, %ebp
; X32-NEXT:    .cfi_def_cfa_register %ebp
; X32-NEXT:    andl $-8, %esp
; X32-NEXT:    subl $32, %esp
; X32-NEXT:    movl 12(%ebp), %ecx
; X32-NEXT:    movl 8(%ebp), %eax
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X32-NEXT:    paddw %xmm0, %xmm1
; X32-NEXT:    movdqa {{.*#+}} xmm0 = [255,255,255,255,255,255,255,255]
; X32-NEXT:    pand %xmm0, %xmm1
; X32-NEXT:    packuswb %xmm1, %xmm1
; X32-NEXT:    movq %xmm1, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %xmm1, (%eax)
; X32-NEXT:    paddsb (%ecx), %mm0
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    paddusb (%ecx), %mm0
; X32-NEXT:    movq %mm0, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm2 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1],xmm2[2],xmm0[2],xmm2[3],xmm0[3],xmm2[4],xmm0[4],xmm2[5],xmm0[5],xmm2[6],xmm0[6],xmm2[7],xmm0[7]
; X32-NEXT:    psubw %xmm2, %xmm1
; X32-NEXT:    pand %xmm0, %xmm1
; X32-NEXT:    packuswb %xmm1, %xmm1
; X32-NEXT:    movq %xmm1, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %xmm1, (%eax)
; X32-NEXT:    psubsb (%ecx), %mm0
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    psubusb (%ecx), %mm0
; X32-NEXT:    movq %mm0, (%esp)
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm2 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1],xmm2[2],xmm0[2],xmm2[3],xmm0[3],xmm2[4],xmm0[4],xmm2[5],xmm0[5],xmm2[6],xmm0[6],xmm2[7],xmm0[7]
; X32-NEXT:    pmullw %xmm1, %xmm2
; X32-NEXT:    movdqa %xmm2, %xmm1
; X32-NEXT:    pand %xmm0, %xmm1
; X32-NEXT:    packuswb %xmm1, %xmm1
; X32-NEXT:    movq %xmm1, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X32-NEXT:    pand %xmm2, %xmm1
; X32-NEXT:    movdqa %xmm1, %xmm2
; X32-NEXT:    pand %xmm0, %xmm2
; X32-NEXT:    packuswb %xmm2, %xmm2
; X32-NEXT:    movq %xmm2, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm2 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1],xmm2[2],xmm0[2],xmm2[3],xmm0[3],xmm2[4],xmm0[4],xmm2[5],xmm0[5],xmm2[6],xmm0[6],xmm2[7],xmm0[7]
; X32-NEXT:    por %xmm1, %xmm2
; X32-NEXT:    movdqa %xmm2, %xmm1
; X32-NEXT:    pand %xmm0, %xmm1
; X32-NEXT:    packuswb %xmm1, %xmm1
; X32-NEXT:    movq %xmm1, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X32-NEXT:    pxor %xmm2, %xmm1
; X32-NEXT:    pand %xmm0, %xmm1
; X32-NEXT:    packuswb %xmm1, %xmm1
; X32-NEXT:    movq %xmm1, (%eax)
; X32-NEXT:    emms
; X32-NEXT:    movl %ebp, %esp
; X32-NEXT:    popl %ebp
; X32-NEXT:    .cfi_def_cfa %esp, 4
; X32-NEXT:    retl
;
; X64-LABEL: test0:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X64-NEXT:    paddw %xmm0, %xmm1
; X64-NEXT:    movdqa {{.*#+}} xmm0 = [255,255,255,255,255,255,255,255]
; X64-NEXT:    pand %xmm0, %xmm1
; X64-NEXT:    packuswb %xmm1, %xmm1
; X64-NEXT:    movq %xmm1, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq -{{[0-9]+}}(%rsp), %mm0
; X64-NEXT:    movq %xmm1, (%rdi)
; X64-NEXT:    paddsb (%rsi), %mm0
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    paddusb (%rsi), %mm0
; X64-NEXT:    movq %mm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm2 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1],xmm2[2],xmm0[2],xmm2[3],xmm0[3],xmm2[4],xmm0[4],xmm2[5],xmm0[5],xmm2[6],xmm0[6],xmm2[7],xmm0[7]
; X64-NEXT:    psubw %xmm2, %xmm1
; X64-NEXT:    pand %xmm0, %xmm1
; X64-NEXT:    packuswb %xmm1, %xmm1
; X64-NEXT:    movq %xmm1, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq -{{[0-9]+}}(%rsp), %mm0
; X64-NEXT:    movq %xmm1, (%rdi)
; X64-NEXT:    psubsb (%rsi), %mm0
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    psubusb (%rsi), %mm0
; X64-NEXT:    movq %mm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm2 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1],xmm2[2],xmm0[2],xmm2[3],xmm0[3],xmm2[4],xmm0[4],xmm2[5],xmm0[5],xmm2[6],xmm0[6],xmm2[7],xmm0[7]
; X64-NEXT:    pmullw %xmm1, %xmm2
; X64-NEXT:    movdqa %xmm2, %xmm1
; X64-NEXT:    pand %xmm0, %xmm1
; X64-NEXT:    packuswb %xmm1, %xmm1
; X64-NEXT:    movq %xmm1, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X64-NEXT:    pand %xmm2, %xmm1
; X64-NEXT:    movdqa %xmm1, %xmm2
; X64-NEXT:    pand %xmm0, %xmm2
; X64-NEXT:    packuswb %xmm2, %xmm2
; X64-NEXT:    movq %xmm2, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm2 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm2 = xmm2[0],xmm0[0],xmm2[1],xmm0[1],xmm2[2],xmm0[2],xmm2[3],xmm0[3],xmm2[4],xmm0[4],xmm2[5],xmm0[5],xmm2[6],xmm0[6],xmm2[7],xmm0[7]
; X64-NEXT:    por %xmm1, %xmm2
; X64-NEXT:    movdqa %xmm2, %xmm1
; X64-NEXT:    pand %xmm0, %xmm1
; X64-NEXT:    packuswb %xmm1, %xmm1
; X64-NEXT:    movq %xmm1, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3],xmm1[4],xmm0[4],xmm1[5],xmm0[5],xmm1[6],xmm0[6],xmm1[7],xmm0[7]
; X64-NEXT:    pxor %xmm2, %xmm1
; X64-NEXT:    pand %xmm0, %xmm1
; X64-NEXT:    packuswb %xmm1, %xmm1
; X64-NEXT:    movq %xmm1, (%rdi)
; X64-NEXT:    emms
; X64-NEXT:    retq
entry:
  %tmp1 = load x86_mmx, x86_mmx* %A
  %tmp3 = load x86_mmx, x86_mmx* %B
  %tmp1a = bitcast x86_mmx %tmp1 to <8 x i8>
  %tmp3a = bitcast x86_mmx %tmp3 to <8 x i8>
  %tmp4 = add <8 x i8> %tmp1a, %tmp3a
  %tmp4a = bitcast <8 x i8> %tmp4 to x86_mmx
  store x86_mmx %tmp4a, x86_mmx* %A
  %tmp7 = load x86_mmx, x86_mmx* %B
  %tmp12 = tail call x86_mmx @llvm.x86.mmx.padds.b(x86_mmx %tmp4a, x86_mmx %tmp7)
  store x86_mmx %tmp12, x86_mmx* %A
  %tmp16 = load x86_mmx, x86_mmx* %B
  %tmp21 = tail call x86_mmx @llvm.x86.mmx.paddus.b(x86_mmx %tmp12, x86_mmx %tmp16)
  store x86_mmx %tmp21, x86_mmx* %A
  %tmp27 = load x86_mmx, x86_mmx* %B
  %tmp21a = bitcast x86_mmx %tmp21 to <8 x i8>
  %tmp27a = bitcast x86_mmx %tmp27 to <8 x i8>
  %tmp28 = sub <8 x i8> %tmp21a, %tmp27a
  %tmp28a = bitcast <8 x i8> %tmp28 to x86_mmx
  store x86_mmx %tmp28a, x86_mmx* %A
  %tmp31 = load x86_mmx, x86_mmx* %B
  %tmp36 = tail call x86_mmx @llvm.x86.mmx.psubs.b(x86_mmx %tmp28a, x86_mmx %tmp31)
  store x86_mmx %tmp36, x86_mmx* %A
  %tmp40 = load x86_mmx, x86_mmx* %B
  %tmp45 = tail call x86_mmx @llvm.x86.mmx.psubus.b(x86_mmx %tmp36, x86_mmx %tmp40)
  store x86_mmx %tmp45, x86_mmx* %A
  %tmp51 = load x86_mmx, x86_mmx* %B
  %tmp45a = bitcast x86_mmx %tmp45 to <8 x i8>
  %tmp51a = bitcast x86_mmx %tmp51 to <8 x i8>
  %tmp52 = mul <8 x i8> %tmp45a, %tmp51a
  %tmp52a = bitcast <8 x i8> %tmp52 to x86_mmx
  store x86_mmx %tmp52a, x86_mmx* %A
  %tmp57 = load x86_mmx, x86_mmx* %B
  %tmp57a = bitcast x86_mmx %tmp57 to <8 x i8>
  %tmp58 = and <8 x i8> %tmp52, %tmp57a
  %tmp58a = bitcast <8 x i8> %tmp58 to x86_mmx
  store x86_mmx %tmp58a, x86_mmx* %A
  %tmp63 = load x86_mmx, x86_mmx* %B
  %tmp63a = bitcast x86_mmx %tmp63 to <8 x i8>
  %tmp64 = or <8 x i8> %tmp58, %tmp63a
  %tmp64a = bitcast <8 x i8> %tmp64 to x86_mmx
  store x86_mmx %tmp64a, x86_mmx* %A
  %tmp69 = load x86_mmx, x86_mmx* %B
  %tmp69a = bitcast x86_mmx %tmp69 to <8 x i8>
  %tmp64b = bitcast x86_mmx %tmp64a to <8 x i8>
  %tmp70 = xor <8 x i8> %tmp64b, %tmp69a
  %tmp70a = bitcast <8 x i8> %tmp70 to x86_mmx
  store x86_mmx %tmp70a, x86_mmx* %A
  tail call void @llvm.x86.mmx.emms()
  ret void
}

define void @test1(x86_mmx* %A, x86_mmx* %B) {
; X32-LABEL: test1:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    movsd {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    shufps {{.*#+}} xmm0 = xmm0[0,1,1,3]
; X32-NEXT:    movsd {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    shufps {{.*#+}} xmm1 = xmm1[0,1,1,3]
; X32-NEXT:    paddq %xmm0, %xmm1
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm1[0,2,2,3]
; X32-NEXT:    movq %xmm0, (%eax)
; X32-NEXT:    movsd {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    shufps {{.*#+}} xmm0 = xmm0[0,1,1,3]
; X32-NEXT:    pmuludq %xmm1, %xmm0
; X32-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[0,2,2,3]
; X32-NEXT:    movq %xmm1, (%eax)
; X32-NEXT:    movsd {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    shufps {{.*#+}} xmm1 = xmm1[0,1,1,3]
; X32-NEXT:    andps %xmm0, %xmm1
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm1[0,2,2,3]
; X32-NEXT:    movq %xmm0, (%eax)
; X32-NEXT:    movsd {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    shufps {{.*#+}} xmm0 = xmm0[0,1,1,3]
; X32-NEXT:    orps %xmm1, %xmm0
; X32-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[0,2,2,3]
; X32-NEXT:    movq %xmm1, (%eax)
; X32-NEXT:    movsd {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    shufps {{.*#+}} xmm1 = xmm1[0,1,1,3]
; X32-NEXT:    xorps %xmm0, %xmm1
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm1[0,2,2,3]
; X32-NEXT:    movq %xmm0, (%eax)
; X32-NEXT:    emms
; X32-NEXT:    retl
;
; X64-LABEL: test1:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,1,1,3]
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,1,1,3]
; X64-NEXT:    paddq %xmm0, %xmm1
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm1[0,2,2,3]
; X64-NEXT:    movq %xmm0, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,1,1,3]
; X64-NEXT:    pmuludq %xmm1, %xmm0
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[0,2,2,3]
; X64-NEXT:    movq %xmm1, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,1,1,3]
; X64-NEXT:    pand %xmm0, %xmm1
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm1[0,2,2,3]
; X64-NEXT:    movq %xmm0, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,1,1,3]
; X64-NEXT:    por %xmm1, %xmm0
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[0,2,2,3]
; X64-NEXT:    movq %xmm1, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,1,1,3]
; X64-NEXT:    pxor %xmm0, %xmm1
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm1[0,2,2,3]
; X64-NEXT:    movq %xmm0, (%rdi)
; X64-NEXT:    emms
; X64-NEXT:    retq
entry:
  %tmp1 = load x86_mmx, x86_mmx* %A
  %tmp3 = load x86_mmx, x86_mmx* %B
  %tmp1a = bitcast x86_mmx %tmp1 to <2 x i32>
  %tmp3a = bitcast x86_mmx %tmp3 to <2 x i32>
  %tmp4 = add <2 x i32> %tmp1a, %tmp3a
  %tmp4a = bitcast <2 x i32> %tmp4 to x86_mmx
  store x86_mmx %tmp4a, x86_mmx* %A
  %tmp9 = load x86_mmx, x86_mmx* %B
  %tmp9a = bitcast x86_mmx %tmp9 to <2 x i32>
  %tmp10 = sub <2 x i32> %tmp4, %tmp9a
  %tmp10a = bitcast <2 x i32> %tmp4 to x86_mmx
  store x86_mmx %tmp10a, x86_mmx* %A
  %tmp15 = load x86_mmx, x86_mmx* %B
  %tmp10b = bitcast x86_mmx %tmp10a to <2 x i32>
  %tmp15a = bitcast x86_mmx %tmp15 to <2 x i32>
  %tmp16 = mul <2 x i32> %tmp10b, %tmp15a
  %tmp16a = bitcast <2 x i32> %tmp16 to x86_mmx
  store x86_mmx %tmp16a, x86_mmx* %A
  %tmp21 = load x86_mmx, x86_mmx* %B
  %tmp16b = bitcast x86_mmx %tmp16a to <2 x i32>
  %tmp21a = bitcast x86_mmx %tmp21 to <2 x i32>
  %tmp22 = and <2 x i32> %tmp16b, %tmp21a
  %tmp22a = bitcast <2 x i32> %tmp22 to x86_mmx
  store x86_mmx %tmp22a, x86_mmx* %A
  %tmp27 = load x86_mmx, x86_mmx* %B
  %tmp22b = bitcast x86_mmx %tmp22a to <2 x i32>
  %tmp27a = bitcast x86_mmx %tmp27 to <2 x i32>
  %tmp28 = or <2 x i32> %tmp22b, %tmp27a
  %tmp28a = bitcast <2 x i32> %tmp28 to x86_mmx
  store x86_mmx %tmp28a, x86_mmx* %A
  %tmp33 = load x86_mmx, x86_mmx* %B
  %tmp28b = bitcast x86_mmx %tmp28a to <2 x i32>
  %tmp33a = bitcast x86_mmx %tmp33 to <2 x i32>
  %tmp34 = xor <2 x i32> %tmp28b, %tmp33a
  %tmp34a = bitcast <2 x i32> %tmp34 to x86_mmx
  store x86_mmx %tmp34a, x86_mmx* %A
  tail call void @llvm.x86.mmx.emms( )
  ret void
}

define void @test2(x86_mmx* %A, x86_mmx* %B) {
; X32-LABEL: test2:
; X32:       # %bb.0: # %entry
; X32-NEXT:    pushl %ebp
; X32-NEXT:    .cfi_def_cfa_offset 8
; X32-NEXT:    .cfi_offset %ebp, -8
; X32-NEXT:    movl %esp, %ebp
; X32-NEXT:    .cfi_def_cfa_register %ebp
; X32-NEXT:    andl $-8, %esp
; X32-NEXT:    subl $48, %esp
; X32-NEXT:    movl 12(%ebp), %ecx
; X32-NEXT:    movl 8(%ebp), %eax
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X32-NEXT:    paddd %xmm0, %xmm1
; X32-NEXT:    pshuflw {{.*#+}} xmm0 = xmm1[0,2,2,3,4,5,6,7]
; X32-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X32-NEXT:    movq %xmm0, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %xmm0, (%eax)
; X32-NEXT:    paddsw (%ecx), %mm0
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    paddusw (%ecx), %mm0
; X32-NEXT:    movq %mm0, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X32-NEXT:    psubd %xmm1, %xmm0
; X32-NEXT:    pshuflw {{.*#+}} xmm0 = xmm0[0,2,2,3,4,5,6,7]
; X32-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X32-NEXT:    movq %xmm0, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %xmm0, (%eax)
; X32-NEXT:    psubsw (%ecx), %mm0
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    psubusw (%ecx), %mm0
; X32-NEXT:    movq %mm0, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X32-NEXT:    pshufd {{.*#+}} xmm2 = xmm0[1,1,3,3]
; X32-NEXT:    pmuludq %xmm1, %xmm0
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X32-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[1,1,3,3]
; X32-NEXT:    pmuludq %xmm2, %xmm1
; X32-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,2,2,3]
; X32-NEXT:    punpckldq {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
; X32-NEXT:    pshuflw {{.*#+}} xmm0 = xmm0[0,2,2,3,4,5,6,7]
; X32-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X32-NEXT:    movq %xmm0, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %xmm0, (%eax)
; X32-NEXT:    pmulhw (%ecx), %mm0
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    pmaddwd (%ecx), %mm0
; X32-NEXT:    movq %mm0, (%esp)
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X32-NEXT:    movq %mm0, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X32-NEXT:    pand %xmm0, %xmm1
; X32-NEXT:    pshuflw {{.*#+}} xmm0 = xmm1[0,2,2,3,4,5,6,7]
; X32-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X32-NEXT:    movq %xmm0, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X32-NEXT:    por %xmm1, %xmm0
; X32-NEXT:    pshuflw {{.*#+}} xmm1 = xmm0[0,2,2,3,4,5,6,7]
; X32-NEXT:    pshufhw {{.*#+}} xmm1 = xmm1[0,1,2,3,4,6,6,7]
; X32-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,2,2,3]
; X32-NEXT:    movq %xmm1, (%eax)
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X32-NEXT:    pxor %xmm0, %xmm1
; X32-NEXT:    pshuflw {{.*#+}} xmm0 = xmm1[0,2,2,3,4,5,6,7]
; X32-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X32-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X32-NEXT:    movq %xmm0, (%eax)
; X32-NEXT:    emms
; X32-NEXT:    movl %ebp, %esp
; X32-NEXT:    popl %ebp
; X32-NEXT:    .cfi_def_cfa %esp, 4
; X32-NEXT:    retl
;
; X64-LABEL: test2:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X64-NEXT:    paddd %xmm0, %xmm1
; X64-NEXT:    pshuflw {{.*#+}} xmm0 = xmm1[0,2,2,3,4,5,6,7]
; X64-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X64-NEXT:    movq %xmm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq -{{[0-9]+}}(%rsp), %mm0
; X64-NEXT:    movq %xmm0, (%rdi)
; X64-NEXT:    paddsw (%rsi), %mm0
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    paddusw (%rsi), %mm0
; X64-NEXT:    movq %mm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X64-NEXT:    psubd %xmm1, %xmm0
; X64-NEXT:    pshuflw {{.*#+}} xmm0 = xmm0[0,2,2,3,4,5,6,7]
; X64-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X64-NEXT:    movq %xmm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq -{{[0-9]+}}(%rsp), %mm0
; X64-NEXT:    movq %xmm0, (%rdi)
; X64-NEXT:    psubsw (%rsi), %mm0
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    psubusw (%rsi), %mm0
; X64-NEXT:    movq %mm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X64-NEXT:    pshufd {{.*#+}} xmm2 = xmm0[1,1,3,3]
; X64-NEXT:    pmuludq %xmm1, %xmm0
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[1,1,3,3]
; X64-NEXT:    pmuludq %xmm2, %xmm1
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,2,2,3]
; X64-NEXT:    punpckldq {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1]
; X64-NEXT:    pshuflw {{.*#+}} xmm0 = xmm0[0,2,2,3,4,5,6,7]
; X64-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X64-NEXT:    movq %xmm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq -{{[0-9]+}}(%rsp), %mm0
; X64-NEXT:    movq %xmm0, (%rdi)
; X64-NEXT:    pmulhw (%rsi), %mm0
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    pmaddwd (%rsi), %mm0
; X64-NEXT:    movq %mm0, -{{[0-9]+}}(%rsp)
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X64-NEXT:    movq %mm0, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X64-NEXT:    pand %xmm0, %xmm1
; X64-NEXT:    pshuflw {{.*#+}} xmm0 = xmm1[0,2,2,3,4,5,6,7]
; X64-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X64-NEXT:    movq %xmm0, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; X64-NEXT:    por %xmm1, %xmm0
; X64-NEXT:    pshuflw {{.*#+}} xmm1 = xmm0[0,2,2,3,4,5,6,7]
; X64-NEXT:    pshufhw {{.*#+}} xmm1 = xmm1[0,1,2,3,4,6,6,7]
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,2,2,3]
; X64-NEXT:    movq %xmm1, (%rdi)
; X64-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X64-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm0[0],xmm1[1],xmm0[1],xmm1[2],xmm0[2],xmm1[3],xmm0[3]
; X64-NEXT:    pxor %xmm0, %xmm1
; X64-NEXT:    pshuflw {{.*#+}} xmm0 = xmm1[0,2,2,3,4,5,6,7]
; X64-NEXT:    pshufhw {{.*#+}} xmm0 = xmm0[0,1,2,3,4,6,6,7]
; X64-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; X64-NEXT:    movq %xmm0, (%rdi)
; X64-NEXT:    emms
; X64-NEXT:    retq
entry:
  %tmp1 = load x86_mmx, x86_mmx* %A
  %tmp3 = load x86_mmx, x86_mmx* %B
  %tmp1a = bitcast x86_mmx %tmp1 to <4 x i16>
  %tmp3a = bitcast x86_mmx %tmp3 to <4 x i16>
  %tmp4 = add <4 x i16> %tmp1a, %tmp3a
  %tmp4a = bitcast <4 x i16> %tmp4 to x86_mmx
  store x86_mmx %tmp4a, x86_mmx* %A
  %tmp7 = load x86_mmx, x86_mmx* %B
  %tmp12 = tail call x86_mmx @llvm.x86.mmx.padds.w(x86_mmx %tmp4a, x86_mmx %tmp7)
  store x86_mmx %tmp12, x86_mmx* %A
  %tmp16 = load x86_mmx, x86_mmx* %B
  %tmp21 = tail call x86_mmx @llvm.x86.mmx.paddus.w(x86_mmx %tmp12, x86_mmx %tmp16)
  store x86_mmx %tmp21, x86_mmx* %A
  %tmp27 = load x86_mmx, x86_mmx* %B
  %tmp21a = bitcast x86_mmx %tmp21 to <4 x i16>
  %tmp27a = bitcast x86_mmx %tmp27 to <4 x i16>
  %tmp28 = sub <4 x i16> %tmp21a, %tmp27a
  %tmp28a = bitcast <4 x i16> %tmp28 to x86_mmx
  store x86_mmx %tmp28a, x86_mmx* %A
  %tmp31 = load x86_mmx, x86_mmx* %B
  %tmp36 = tail call x86_mmx @llvm.x86.mmx.psubs.w(x86_mmx %tmp28a, x86_mmx %tmp31)
  store x86_mmx %tmp36, x86_mmx* %A
  %tmp40 = load x86_mmx, x86_mmx* %B
  %tmp45 = tail call x86_mmx @llvm.x86.mmx.psubus.w(x86_mmx %tmp36, x86_mmx %tmp40)
  store x86_mmx %tmp45, x86_mmx* %A
  %tmp51 = load x86_mmx, x86_mmx* %B
  %tmp45a = bitcast x86_mmx %tmp45 to <4 x i16>
  %tmp51a = bitcast x86_mmx %tmp51 to <4 x i16>
  %tmp52 = mul <4 x i16> %tmp45a, %tmp51a
  %tmp52a = bitcast <4 x i16> %tmp52 to x86_mmx
  store x86_mmx %tmp52a, x86_mmx* %A
  %tmp55 = load x86_mmx, x86_mmx* %B
  %tmp60 = tail call x86_mmx @llvm.x86.mmx.pmulh.w(x86_mmx %tmp52a, x86_mmx %tmp55)
  store x86_mmx %tmp60, x86_mmx* %A
  %tmp64 = load x86_mmx, x86_mmx* %B
  %tmp69 = tail call x86_mmx @llvm.x86.mmx.pmadd.wd(x86_mmx %tmp60, x86_mmx %tmp64)
  %tmp70 = bitcast x86_mmx %tmp69 to x86_mmx
  store x86_mmx %tmp70, x86_mmx* %A
  %tmp75 = load x86_mmx, x86_mmx* %B
  %tmp70a = bitcast x86_mmx %tmp70 to <4 x i16>
  %tmp75a = bitcast x86_mmx %tmp75 to <4 x i16>
  %tmp76 = and <4 x i16> %tmp70a, %tmp75a
  %tmp76a = bitcast <4 x i16> %tmp76 to x86_mmx
  store x86_mmx %tmp76a, x86_mmx* %A
  %tmp81 = load x86_mmx, x86_mmx* %B
  %tmp76b = bitcast x86_mmx %tmp76a to <4 x i16>
  %tmp81a = bitcast x86_mmx %tmp81 to <4 x i16>
  %tmp82 = or <4 x i16> %tmp76b, %tmp81a
  %tmp82a = bitcast <4 x i16> %tmp82 to x86_mmx
  store x86_mmx %tmp82a, x86_mmx* %A
  %tmp87 = load x86_mmx, x86_mmx* %B
  %tmp82b = bitcast x86_mmx %tmp82a to <4 x i16>
  %tmp87a = bitcast x86_mmx %tmp87 to <4 x i16>
  %tmp88 = xor <4 x i16> %tmp82b, %tmp87a
  %tmp88a = bitcast <4 x i16> %tmp88 to x86_mmx
  store x86_mmx %tmp88a, x86_mmx* %A
  tail call void @llvm.x86.mmx.emms( )
  ret void
}

define <1 x i64> @test3(<1 x i64>* %a, <1 x i64>* %b, i32 %count) nounwind {
; X32-LABEL: test3:
; X32:       # %bb.0: # %entry
; X32-NEXT:    pushl %ebp
; X32-NEXT:    movl %esp, %ebp
; X32-NEXT:    pushl %ebx
; X32-NEXT:    pushl %edi
; X32-NEXT:    pushl %esi
; X32-NEXT:    andl $-8, %esp
; X32-NEXT:    subl $16, %esp
; X32-NEXT:    cmpl $0, 16(%ebp)
; X32-NEXT:    je .LBB3_1
; X32-NEXT:  # %bb.2: # %bb26.preheader
; X32-NEXT:    xorl %ebx, %ebx
; X32-NEXT:    xorl %eax, %eax
; X32-NEXT:    xorl %edx, %edx
; X32-NEXT:    .p2align 4, 0x90
; X32-NEXT:  .LBB3_3: # %bb26
; X32-NEXT:    # =>This Inner Loop Header: Depth=1
; X32-NEXT:    movl 8(%ebp), %ecx
; X32-NEXT:    movl %ecx, %esi
; X32-NEXT:    movl (%ecx,%ebx,8), %ecx
; X32-NEXT:    movl 4(%esi,%ebx,8), %esi
; X32-NEXT:    movl 12(%ebp), %edi
; X32-NEXT:    addl (%edi,%ebx,8), %ecx
; X32-NEXT:    adcl 4(%edi,%ebx,8), %esi
; X32-NEXT:    addl %eax, %ecx
; X32-NEXT:    movl %ecx, (%esp)
; X32-NEXT:    adcl %edx, %esi
; X32-NEXT:    movl %esi, {{[0-9]+}}(%esp)
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    movd %xmm0, %eax
; X32-NEXT:    shufps {{.*#+}} xmm0 = xmm0[1,1,0,1]
; X32-NEXT:    movd %xmm0, %edx
; X32-NEXT:    incl %ebx
; X32-NEXT:    cmpl 16(%ebp), %ebx
; X32-NEXT:    jb .LBB3_3
; X32-NEXT:    jmp .LBB3_4
; X32-NEXT:  .LBB3_1:
; X32-NEXT:    xorl %eax, %eax
; X32-NEXT:    xorl %edx, %edx
; X32-NEXT:  .LBB3_4: # %bb31
; X32-NEXT:    leal -12(%ebp), %esp
; X32-NEXT:    popl %esi
; X32-NEXT:    popl %edi
; X32-NEXT:    popl %ebx
; X32-NEXT:    popl %ebp
; X32-NEXT:    retl
;
; X64-LABEL: test3:
; X64:       # %bb.0: # %entry
; X64-NEXT:    xorl %r8d, %r8d
; X64-NEXT:    xorl %eax, %eax
; X64-NEXT:    testl %edx, %edx
; X64-NEXT:    je .LBB3_2
; X64-NEXT:    .p2align 4, 0x90
; X64-NEXT:  .LBB3_1: # %bb26
; X64-NEXT:    # =>This Inner Loop Header: Depth=1
; X64-NEXT:    movslq %r8d, %r8
; X64-NEXT:    movq (%rdi,%r8,8), %rcx
; X64-NEXT:    addq (%rsi,%r8,8), %rcx
; X64-NEXT:    addq %rcx, %rax
; X64-NEXT:    incl %r8d
; X64-NEXT:    cmpl %edx, %r8d
; X64-NEXT:    jb .LBB3_1
; X64-NEXT:  .LBB3_2: # %bb31
; X64-NEXT:    retq
entry:
  %tmp2942 = icmp eq i32 %count, 0
  br i1 %tmp2942, label %bb31, label %bb26

bb26:
  %i.037.0 = phi i32 [ 0, %entry ], [ %tmp25, %bb26 ]
  %sum.035.0 = phi <1 x i64> [ zeroinitializer, %entry ], [ %tmp22, %bb26 ]
  %tmp13 = getelementptr <1 x i64>, <1 x i64>* %b, i32 %i.037.0
  %tmp14 = load <1 x i64>, <1 x i64>* %tmp13
  %tmp18 = getelementptr <1 x i64>, <1 x i64>* %a, i32 %i.037.0
  %tmp19 = load <1 x i64>, <1 x i64>* %tmp18
  %tmp21 = add <1 x i64> %tmp19, %tmp14
  %tmp22 = add <1 x i64> %tmp21, %sum.035.0
  %tmp25 = add i32 %i.037.0, 1
  %tmp29 = icmp ult i32 %tmp25, %count
  br i1 %tmp29, label %bb26, label %bb31

bb31:
  %sum.035.1 = phi <1 x i64> [ zeroinitializer, %entry ], [ %tmp22, %bb26 ]
  ret <1 x i64> %sum.035.1
}

; There are no MMX operations here, so we use XMM or i64.
define void @ti8(double %a, double %b) nounwind {
; X32-LABEL: ti8:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    paddb %xmm0, %xmm1
; X32-NEXT:    movq %xmm1, 0
; X32-NEXT:    retl
;
; X64-LABEL: ti8:
; X64:       # %bb.0: # %entry
; X64-NEXT:    paddb %xmm1, %xmm0
; X64-NEXT:    movq %xmm0, 0
; X64-NEXT:    retq
entry:
  %tmp1 = bitcast double %a to <8 x i8>
  %tmp2 = bitcast double %b to <8 x i8>
  %tmp3 = add <8 x i8> %tmp1, %tmp2
  store <8 x i8> %tmp3, <8 x i8>* null
  ret void
}

define void @ti16(double %a, double %b) nounwind {
; X32-LABEL: ti16:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    paddw %xmm0, %xmm1
; X32-NEXT:    movq %xmm1, 0
; X32-NEXT:    retl
;
; X64-LABEL: ti16:
; X64:       # %bb.0: # %entry
; X64-NEXT:    paddw %xmm1, %xmm0
; X64-NEXT:    movq %xmm0, 0
; X64-NEXT:    retq
entry:
  %tmp1 = bitcast double %a to <4 x i16>
  %tmp2 = bitcast double %b to <4 x i16>
  %tmp3 = add <4 x i16> %tmp1, %tmp2
  store <4 x i16> %tmp3, <4 x i16>* null
  ret void
}

define void @ti32(double %a, double %b) nounwind {
; X32-LABEL: ti32:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; X32-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; X32-NEXT:    paddd %xmm0, %xmm1
; X32-NEXT:    movq %xmm1, 0
; X32-NEXT:    retl
;
; X64-LABEL: ti32:
; X64:       # %bb.0: # %entry
; X64-NEXT:    paddd %xmm1, %xmm0
; X64-NEXT:    movq %xmm0, 0
; X64-NEXT:    retq
entry:
  %tmp1 = bitcast double %a to <2 x i32>
  %tmp2 = bitcast double %b to <2 x i32>
  %tmp3 = add <2 x i32> %tmp1, %tmp2
  store <2 x i32> %tmp3, <2 x i32>* null
  ret void
}

define void @ti64(double %a, double %b) nounwind {
; X32-LABEL: ti64:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X32-NEXT:    addl {{[0-9]+}}(%esp), %eax
; X32-NEXT:    adcl {{[0-9]+}}(%esp), %ecx
; X32-NEXT:    movl %eax, 0
; X32-NEXT:    movl %ecx, 4
; X32-NEXT:    retl
;
; X64-LABEL: ti64:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movq %xmm0, %rax
; X64-NEXT:    movq %xmm1, %rcx
; X64-NEXT:    addq %rax, %rcx
; X64-NEXT:    movq %rcx, 0
; X64-NEXT:    retq
entry:
  %tmp1 = bitcast double %a to <1 x i64>
  %tmp2 = bitcast double %b to <1 x i64>
  %tmp3 = add <1 x i64> %tmp1, %tmp2
  store <1 x i64> %tmp3, <1 x i64>* null
  ret void
}

; MMX intrinsics calls get us MMX instructions.
define void @ti8a(double %a, double %b) nounwind {
; X32-LABEL: ti8a:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    paddb {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %mm0, 0
; X32-NEXT:    retl
;
; X64-LABEL: ti8a:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movdq2q %xmm0, %mm0
; X64-NEXT:    movdq2q %xmm1, %mm1
; X64-NEXT:    paddb %mm0, %mm1
; X64-NEXT:    movq %mm1, 0
; X64-NEXT:    retq
entry:
  %tmp1 = bitcast double %a to x86_mmx
  %tmp2 = bitcast double %b to x86_mmx
  %tmp3 = tail call x86_mmx @llvm.x86.mmx.padd.b(x86_mmx %tmp1, x86_mmx %tmp2)
  store x86_mmx %tmp3, x86_mmx* null
  ret void
}

define void @ti16a(double %a, double %b) nounwind {
; X32-LABEL: ti16a:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    paddw {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %mm0, 0
; X32-NEXT:    retl
;
; X64-LABEL: ti16a:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movdq2q %xmm0, %mm0
; X64-NEXT:    movdq2q %xmm1, %mm1
; X64-NEXT:    paddw %mm0, %mm1
; X64-NEXT:    movq %mm1, 0
; X64-NEXT:    retq
entry:
  %tmp1 = bitcast double %a to x86_mmx
  %tmp2 = bitcast double %b to x86_mmx
  %tmp3 = tail call x86_mmx @llvm.x86.mmx.padd.w(x86_mmx %tmp1, x86_mmx %tmp2)
  store x86_mmx %tmp3, x86_mmx* null
  ret void
}

define void @ti32a(double %a, double %b) nounwind {
; X32-LABEL: ti32a:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    paddd {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %mm0, 0
; X32-NEXT:    retl
;
; X64-LABEL: ti32a:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movdq2q %xmm0, %mm0
; X64-NEXT:    movdq2q %xmm1, %mm1
; X64-NEXT:    paddd %mm0, %mm1
; X64-NEXT:    movq %mm1, 0
; X64-NEXT:    retq
entry:
  %tmp1 = bitcast double %a to x86_mmx
  %tmp2 = bitcast double %b to x86_mmx
  %tmp3 = tail call x86_mmx @llvm.x86.mmx.padd.d(x86_mmx %tmp1, x86_mmx %tmp2)
  store x86_mmx %tmp3, x86_mmx* null
  ret void
}

define void @ti64a(double %a, double %b) nounwind {
; X32-LABEL: ti64a:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    paddq {{[0-9]+}}(%esp), %mm0
; X32-NEXT:    movq %mm0, 0
; X32-NEXT:    retl
;
; X64-LABEL: ti64a:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movdq2q %xmm0, %mm0
; X64-NEXT:    movdq2q %xmm1, %mm1
; X64-NEXT:    paddq %mm0, %mm1
; X64-NEXT:    movq %mm1, 0
; X64-NEXT:    retq
entry:
  %tmp1 = bitcast double %a to x86_mmx
  %tmp2 = bitcast double %b to x86_mmx
  %tmp3 = tail call x86_mmx @llvm.x86.mmx.padd.q(x86_mmx %tmp1, x86_mmx %tmp2)
  store x86_mmx %tmp3, x86_mmx* null
  ret void
}

declare x86_mmx @llvm.x86.mmx.padd.b(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.padd.w(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.padd.d(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.padd.q(x86_mmx, x86_mmx)

declare x86_mmx @llvm.x86.mmx.paddus.b(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.psubus.b(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.paddus.w(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.psubus.w(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.pmulh.w(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.pmadd.wd(x86_mmx, x86_mmx)

declare void @llvm.x86.mmx.emms()

declare x86_mmx @llvm.x86.mmx.padds.b(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.padds.w(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.psubs.b(x86_mmx, x86_mmx)
declare x86_mmx @llvm.x86.mmx.psubs.w(x86_mmx, x86_mmx)

