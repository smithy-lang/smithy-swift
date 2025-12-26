//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema

public protocol DeserializableShape {
    static var schema: Smithy.Schema { get }
    static func deserialize(_ deserializer: ShapeDeserializer) throws -> Self
}
