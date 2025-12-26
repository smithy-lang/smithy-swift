//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol Codec {
    func makeSerializer() throws -> any ShapeSerializer
    func makeDeserializer() throws -> any ShapeDeserializer
}
