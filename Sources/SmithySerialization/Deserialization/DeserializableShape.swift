//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol DeserializableShape {

    mutating func deserialize(_ deserializer: ShapeDeserializer) throws
}
