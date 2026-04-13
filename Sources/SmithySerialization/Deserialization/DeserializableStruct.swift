//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Schema

public typealias ReadStructConsumer<T> = (Schema, inout T, any ShapeDeserializer) throws -> Void

public protocol DeserializableStruct: DeserializableShape {
    static var readConsumer: ReadStructConsumer<Self> { get }
}
