//===-- ComplexToROCDLLibraryCalls.cpp - conversion from Complex to ROCDL library calls -===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/ComplexToROCDLLibraryCalls/ComplexToROCDLLibraryCalls.h"

#include "mlir/Dialect/Complex/IR/Complex.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/Pass/Pass.h"
#include <optional>

namespace mlir {
#define GEN_PASS_DEF_CONVERTCOMPLEXTOROCDLLIBRARYCALLS
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;

namespace {

template <typename Op, typename FloatTy>
struct ScalarOpToROCDLCall : public OpRewritePattern<Op> {
  using OpRewritePattern<Op>::OpRewritePattern;
  ScalarOpToROCDLCall(MLIRContext *context, StringRef funcName,
                      PatternBenefit benefit)
      : OpRewritePattern<Op>(context, benefit), funcName(funcName) {}

  LogicalResult matchAndRewrite(Op op, PatternRewriter &rewriter) const final {
    Type elementTy = getElementTypeOrSelf(op.getType());
    if (!elementTy.template isa<FloatTy>())
      return failure();

    auto module = SymbolTable::getNearestSymbolTable(op);
    auto opFunc = dyn_cast_or_null<SymbolOpInterface>(
        SymbolTable::lookupSymbolIn(module, funcName));
    if (!opFunc) {
      OpBuilder::InsertionGuard guard(rewriter);
      rewriter.setInsertionPointToStart(&module->getRegion(0).front());
      auto funcTy = FunctionType::get(
          rewriter.getContext(), op->getOperandTypes(), op->getResultTypes());
      opFunc = rewriter.create<func::FuncOp>(rewriter.getUnknownLoc(), funcName,
                                             funcTy);
      opFunc.setPrivate();
    }
    rewriter.replaceOpWithNewOp<func::CallOp>(op, funcName, op.getType(),
                                              op->getOperands());
    return success();
  }

private:
  StringRef funcName;
};
} // namespace

void mlir::populateComplexToROCDLLibraryCallsConversionPatterns(RewritePatternSet &patterns,
                                                                PatternBenefit benefit) {
  patterns.add<ScalarOpToROCDLCall<complex::AbsOp, Float32Type>>(
      patterns.getContext(), "__ocml_cabs_f32", benefit);
  patterns.add<ScalarOpToROCDLCall<complex::AbsOp, Float64Type>>(
      patterns.getContext(), "__ocml_cabs_f64", benefit);
  patterns.add<ScalarOpToROCDLCall<complex::ExpOp, Float32Type>>(
      patterns.getContext(), "__ocml_cexp_f32", benefit);
  patterns.add<ScalarOpToROCDLCall<complex::ExpOp, Float64Type>>(
      patterns.getContext(), "__ocml_cexp_f64", benefit);
}

namespace {
struct ConvertComplexToROCDLLibraryCallsPass
    : public impl::ConvertComplexToROCDLLibraryCallsBase<ConvertComplexToROCDLLibraryCallsPass> {
  void runOnOperation() override {
    auto module = getOperation();

    RewritePatternSet patterns(&getContext());
    populateComplexToROCDLLibraryCallsConversionPatterns(patterns, /*benefit=*/1);

    ConversionTarget target(getContext());
    target.addLegalDialect<func::FuncDialect>();
    target.addIllegalOp<complex::AbsOp, complex::ExpOp>();
    if (failed(applyPartialConversion(module, target, std::move(patterns))))
      signalPassFailure();
  }
};
} // namespace

std::unique_ptr<Pass> mlir::createConvertComplexToROCDLLibraryCallsPass() {
  return std::make_unique<ConvertComplexToROCDLLibraryCallsPass>();
}
