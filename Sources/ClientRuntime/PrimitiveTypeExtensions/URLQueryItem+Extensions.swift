/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import struct Foundation.URLQueryItem
public typealias URLQueryItem = Foundation.URLQueryItem

extension URLQueryItem: Comparable {
    /// Compares two `URLQueryItem` instances by their `name` property.
    /// - Parameters:
    ///  - lhs: The first `URLQueryItem` to compare.
    /// - rhs: The second `URLQueryItem` to compare.
    /// - Returns: `true` if the `name` property of `lhs` is less than the `name` property of `rhs`.
    public static func < (lhs: URLQueryItem, rhs: URLQueryItem) -> Bool {
        lhs.name < rhs.name
    }
}
