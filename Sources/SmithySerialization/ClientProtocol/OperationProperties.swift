//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Schema

public protocol OperationProperties {
    var schema: Schema { get }
    var serviceSchema: Schema { get }
    var inputSchema: Schema { get }
    var outputSchema: Schema { get }
    var errorTypeRegistry: TypeRegistry { get }
}
