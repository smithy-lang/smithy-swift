//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol DeserializableShape: SendableMetatype {
    static func deserialize(_ deserializer: ShapeDeserializer) throws -> Self
}
