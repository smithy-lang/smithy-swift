//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol DeserializableStruct: DeserializableShape {
    static var readConsumer: ReadStructConsumer<Self> { get }
}
