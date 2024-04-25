//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public func doublesMatch(lhs: Double?, rhs: Double?) -> Bool {
    // Both are nil => equal
    if (lhs == nil && rhs == nil) { return true }
    // Only one of them is nil => not equal
    if (lhs == nil || rhs == nil) { return false }
    // Only one of them is NaN => not equal
    if (lhs!.isNaN && !(rhs!.isNaN)) { return false }
    if (!(lhs!.isNaN) && rhs!.isNaN) { return false }
    // Both are NaN => equal
    if (lhs!.isNaN && rhs!.isNaN) { return true }
    // Both are non-nil & non-NaN => equal IFF values equal
    return lhs! == rhs!
}

public func floatsMatch(lhs: Float?, rhs: Float?) -> Bool {
    // Both are nil => equal
    if (lhs == nil && rhs == nil) { return true }
    // Only one of them is nil => not equal
    if (lhs == nil || rhs == nil) { return false }
    // Only one of them is NaN => not equal
    if (lhs!.isNaN && !(rhs!.isNaN)) { return false }
    if (!(lhs!.isNaN) && rhs!.isNaN) { return false }
    // Both are NaN => equal
    if (lhs!.isNaN && rhs!.isNaN) { return true }
    // Both are non-nil & non-NaN => equal IFF values equal
    return lhs! == rhs!
}
