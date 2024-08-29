//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

@_spi(SmithyReadWrite)
public protocol WireDataProviding: AnyObject {

    func data() async throws -> Data
}
