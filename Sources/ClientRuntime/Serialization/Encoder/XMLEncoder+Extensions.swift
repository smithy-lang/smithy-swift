/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import XMLCoder

public typealias XMLEncoder = XMLCoder.XMLEncoder
extension XMLEncoder: RequestEncoder {
    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        return try encode(value, withRootKey: nil, rootAttributes: nil, header: nil)
    }
}
