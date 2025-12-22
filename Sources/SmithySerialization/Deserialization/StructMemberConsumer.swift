//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema

public typealias StructMemberConsumer = (Smithy.Schema, any ShapeDeserializer) throws -> Void
