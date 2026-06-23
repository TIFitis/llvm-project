// RUN: mlir-translate -mlir-to-llvmir %s | FileCheck %s

// Check that a private attach map with a data member is emitted as one regular
// data mapping and one corresponding-pointer-initialized kernel argument. The
// data member itself must not become a second kernel argument.

module attributes {omp.is_target_device = false, omp.target_triples = ["amdgcn-amd-amdhsa"]} {
  llvm.func @main() {
    %c1 = llvm.mlir.constant(1 : i64) : i64
    %desc = llvm.alloca %c1 x !llvm.struct<(ptr, i64, i32, i8, i8, i8, i8)> : (i64) -> !llvm.ptr
    %base_addr = llvm.getelementptr %desc[0, 0] : (!llvm.ptr) -> !llvm.ptr, !llvm.struct<(ptr, i64, i32, i8, i8, i8, i8)>
    %data = omp.map.info var_ptr(%desc : !llvm.ptr, !llvm.struct<(ptr, i64, i32, i8, i8, i8, i8)>) map_clauses(tofrom, implicit) capture(ByRef) var_ptr_ptr(%base_addr : !llvm.ptr, f32) -> !llvm.ptr {name = ""}
    %desc_arg = omp.map.info var_ptr(%desc : !llvm.ptr, !llvm.struct<(ptr, i64, i32, i8, i8, i8, i8)>) map_clauses(private, implicit, attach, ref_ptr) capture(ByRef) var_ptr_ptr(%base_addr : !llvm.ptr, f32) members(%data : [0] : !llvm.ptr) -> !llvm.ptr {name = "a"}
    omp.target map_entries(%desc_arg -> %arg0, %data -> %arg1 : !llvm.ptr, !llvm.ptr) {
      %unused = llvm.load %arg0 : !llvm.ptr -> i64
      omp.terminator
    }
    llvm.return
  }
}

// 515 is TO|FROM|IMPLICIT for the data. 17056 is
// TARGET_PARAM|PRIVATE|IMPLICIT|ATTACH for the descriptor argument.
// CHECK: @.offload_maptypes = private unnamed_addr constant [3 x i64] [i64 515, i64 17056, i64 288]

// Only the descriptor and the implicit dynamic pointer are kernel arguments;
// the descriptor's data map remains runtime-only.
// CHECK: define internal void @{{.*}}(ptr %{{.*}}, ptr %{{.*}}) {
