//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema

public typealias WriteStructConsumer<Element> = (Smithy.Schema, Element, any ShapeSerializer) throws -> Void
