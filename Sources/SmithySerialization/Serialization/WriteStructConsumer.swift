//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Schema

public typealias WriteStructConsumer<T> = (Schema, T, any ShapeSerializer) throws -> Void
