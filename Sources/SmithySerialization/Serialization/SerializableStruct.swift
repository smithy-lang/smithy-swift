//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Schema

public typealias WriteStructConsumer<T> = (Schema, T, any ShapeSerializer) throws -> Void

public protocol SerializableStruct: SerializableShape, CustomStringConvertible, CustomDebugStringConvertible {
    static var writeConsumer: WriteStructConsumer<Self> { get }
}

public extension SerializableStruct {

    /// A written description of this type and its contents.
    ///
    /// Fields marked with the `sensitive` trait will be written to the description as "redacted".
    var description: String {
        let serializer = StringSerializer()
        // Safe to try! here because StringSerializer never throws
        // swiftlint:disable:next force_try
        try! serialize(serializer)
        return serializer.string
    }

    /// A written description of this type and its contents.
    ///
    /// Fields marked with the `sensitive` trait will be written to the description as "redacted".
    var debugDescription: String { description }
}
