!REQUIRES: amdgpu-registered-target
!RUN: %flang_fc1 -triple amdgcn-amd-amdhsa -emit-llvm -fopenmp -fopenmp-is-target-device %s -o - | FileCheck %s

subroutine omp_cabs_f32(a, b)
!$omp declare target
  complex :: a
  real :: b
!CHECK-LABEL: func @_QPomp_cabs_f32(
!CHECK: call float @__ocml_cabs_f32
  b = abs(a)
end subroutine

subroutine omp_cabs_f64(a, b)
!$omp declare target
  complex(8) :: a
  real(8) :: b
!CHECK-LABEL: func @_QPomp_cabs_f64(
!CHECK: call double @__ocml_cabs_f64
  b = abs(a)
end subroutine

