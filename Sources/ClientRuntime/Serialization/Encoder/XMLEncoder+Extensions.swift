//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import SmithyXML

public typealias XMLEncoder = SmithyXML.DocumentWriter

extension DocumentWriter: RequestEncoder {
    public func encode<T: Encodable>(_ value: T) throws -> Data {
//        return try write(value, rootElement: "\(T.self)")
        return Data()
    }
}
