//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Schema

public protocol SerializableShape {
    func serialize(_ serializer: any ShapeSerializer) throws
}
