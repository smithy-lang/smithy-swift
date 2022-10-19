/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import struct Foundation.URLQueryItem
public typealias URLQueryItem = Foundation.URLQueryItem

extension URLQueryItem: Comparable {
    public static func < (lhs: URLQueryItem, rhs: URLQueryItem) -> Bool {
        lhs.name < rhs.name
    }
}
