//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema

public protocol SerializableShape {
    static var schema: Smithy.Schema { get }
    func serialize(_ serializer: any ShapeSerializer)
}
