//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A type enabling O(1) storage of elements that are unique from one another by type.
///
/// These elements are required to be reference types because they are stored using a
/// sparse array of pointers, with the index into the array provided by the type stored.
/// (Value type storage would consume excess memory in the array.)
public protocol UniquelyIndexedByType: AnyObject, Sendable {
    
    /// The unique index for this type.
    ///
    /// Types that will be stored together must have indexes assigned that are unique
    /// from every other type.  The way to achieve this is by implementing this property
    /// by calling `getNextIndex()` on a single ``UniqueIndexCounter``.
    static var uniqueIndex: Int { get }
}

extension UniquelyIndexedByType {

    /// The unique index for this instance's type.
    var uniqueIndex: Int { Self.uniqueIndex }
}
