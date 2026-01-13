//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public protocol Codec: Sendable {
    func makeSerializer() throws -> any ShapeSerializer
    func makeDeserializer(data: Data) throws -> any ShapeDeserializer
}
