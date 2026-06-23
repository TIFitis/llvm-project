! RUN: %flang_fc1 -emit-hlfir -fopenmp %s -o - | FileCheck %s

module implicit_map_contiguous_derived_array
  type bounds
    integer :: first, last
  end type

  type(bounds), allocatable :: values(:)
  !$omp declare target(values)
contains
  subroutine use_size
    integer :: i
    !$omp target teams distribute
    do i = 1, size(values)
    end do
    !$omp end target teams distribute
  end subroutine
end module

! A contiguous derived type with no allocatable components does not require a
! component mapper. In particular, avoid expanding every array element into
! separate four-byte mappings for first and last.
! CHECK-NOT: omp.declare_mapper
! CHECK-LABEL: func.func @_QMimplicit_map_contiguous_derived_arrayPuse_size
! CHECK: %[[DATA_MAP:.*]] = omp.map.info {{.*}} map_clauses(implicit) capture(ByRef) var_ptr_ptr({{.*}}) bounds({{.*}}) -> {{.*}} {name = ""}
! CHECK: %[[DESC_MAP:.*]] = omp.map.info {{.*}} map_clauses(always, implicit, to) capture(ByRef) members(%[[DATA_MAP]]{{.*}}) -> {{.*}} {name = "values"}
! CHECK: omp.target {{.*}}map_entries({{.*}}%[[DESC_MAP]]{{.*}}%[[DATA_MAP]]
