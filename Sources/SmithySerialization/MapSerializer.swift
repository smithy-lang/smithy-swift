//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema

public protocol MapSerializer {
    func writeEntry(_ keySchema: Schema, _ key: String, _ valueConsumer: Consumer<ShapeSerializer>) throws
}
