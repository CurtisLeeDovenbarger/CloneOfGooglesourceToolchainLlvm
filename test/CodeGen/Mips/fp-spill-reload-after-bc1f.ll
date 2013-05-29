; RUN: llc -march=mipsel -O0 < %s | FileCheck %s


declare double @g()

define void @f(i32* sret %result) nounwind {
entry:
  %call = call double @g()
  %cmp = fcmp olt double %call, 1.000000e-07
  br i1 %cmp, label %if.then, label %if.end
; CHECK: {{^ *bc1f }}
; CHECK-NOT: Spill
; CHECK: {{^ *b }}
if.then:                                          ; preds = %entry
  store i32 0, i32* %result
  ret void
if.end:                                           ; preds = %entry
  store i32 1, i32* %result
  ret void
}
