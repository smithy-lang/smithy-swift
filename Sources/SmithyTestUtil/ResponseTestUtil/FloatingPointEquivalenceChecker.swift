//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public func floatingPointValuesMatch<FP: FloatingPoint>(
    lhs: FP?,
    rhs: FP?
) -> Bool {
    if let lhs, let rhs, lhs.isNaN, rhs.isNaN { return true }
    return lhs == rhs
}
