!RUN: %flang_fc1 -fdebug-unparse -fopenmp -fopenmp-version=60 %s | FileCheck %s --check-prefix=UNPARSE
!RUN: %flang_fc1 -fdebug-dump-parse-tree -fopenmp -fopenmp-version=60 %s | FileCheck %s

subroutine s(x)
  integer :: x
  !$omp declare target enter(automap: x)
end

!UNPARSE: SUBROUTINE s (x)
!UNPARSE:  INTEGER x
!UNPARSE: !$OMP DECLARE TARGET  ENTER(AUTOMAP: x)
!UNPARSE: END SUBROUTINE

!CHECK: OmpClauseList -> OmpClause -> Enter -> OmpEnterClause
!CHECK-NEXT: | Modifier -> OmpAutomapModifier -> Value = Automap
!CHECK-NEXT: | OmpObjectList -> OmpObject -> Designator -> DataRef -> Name = 'x'
