//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
public typealias WriteValueConsumer<Element> = (Element, any ShapeSerializer) throws -> Void
