//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public protocol WireDataProviding: AnyObject {

    func data() async throws -> Data
}
