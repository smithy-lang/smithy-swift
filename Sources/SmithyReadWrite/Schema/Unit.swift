//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl) import Smithy

@_spi(SmithyReadWrite)
public struct Unit: Sendable, Equatable, DeserializableShape {

    public init() {}
}
