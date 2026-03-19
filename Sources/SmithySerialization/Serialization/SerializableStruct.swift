//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol SerializableStruct: SerializableShape, CustomDebugStringConvertible {
    static var writeConsumer: WriteStructConsumer<Self> { get }
}

public extension SerializableStruct {

    var debugDescription: String {
        let serializer = StringSerializer()
        // Safe to try! here because StringSerializer never throws
        // swiftlint:disable:next force_try
        try! serialize(serializer)
        return serializer.string
    }
}
