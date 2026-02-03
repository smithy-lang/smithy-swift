//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol SerializableStruct: SerializableShape, CustomDebugStringConvertible {
    static var writeConsumer: WriteStructConsumer<Self> { get }
}
