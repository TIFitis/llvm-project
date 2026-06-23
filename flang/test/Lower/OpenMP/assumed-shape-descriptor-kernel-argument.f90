! RUN: %flang_fc1 -emit-hlfir -fopenmp %s -o - | FileCheck %s

subroutine assumed_shape_descriptor_kernel_argument(a)
  real :: a(:,:)

  !$omp target
  a(1,1) = 1.0
  !$omp end target
end subroutine

! CHECK-LABEL: func.func @_QPassumed_shape_descriptor_kernel_argument
! CHECK: %[[DATA_MAP:.*]] = omp.map.info {{.*}} map_clauses(implicit, tofrom) capture(ByRef) var_ptr_ptr(%[[BASE_ADDR:.*]]{{.*}}) bounds({{.*}}) -> {{.*}} {name = ""}
! CHECK: %[[DESC_ARG:.*]] = omp.map.info {{.*}} map_clauses(implicit, private, attach, ref_ptr) capture(ByRef) var_ptr_ptr(%[[BASE_ADDR]]{{.*}}) members(%[[DATA_MAP]] : [0]{{.*}}) -> {{.*}} {name = "a"}
! CHECK-NOT: map_clauses(always, implicit, to)
! CHECK: omp.target map_entries(%[[DESC_ARG]] -> %[[DESC_BLOCK_ARG:.*]], %[[DATA_MAP]] -> {{.*}})
