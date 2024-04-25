//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public func floatingPointValuesMatch(
    lhs: (any FloatingPoint)?,
    rhs: (any FloatingPoint)?
) -> Bool {
    // Both are nil => equal
    if (lhs == nil && rhs == nil) { return true }
    // Only one of them is nil => not equal
    if (lhs == nil || rhs == nil) { return false }
    // Both are NaN => equal
    if (lhs!.isNaN && rhs!.isNaN) { return true }
    // Only one of them is NaN => not equal
    if (lhs!.isNaN || rhs!.isNaN) { return false }
    // Both are non-nil & non-NaN => equal IFF values equal
    let doubleMatch = (lhs as? Double ?? .nan) == (rhs as? Double ?? .nan)
    let floatMatch = (lhs as? Float ?? .nan) == (rhs as? Float ?? .nan)
    return doubleMatch || floatMatch
}
