//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import enum Smithy.ByteStream
import class SmithyHTTPAPI.HTTPResponse
@_spi(SmithyReadWrite) import protocol SmithyReadWrite.WireDataProviding

@_spi(SmithyReadWrite)
extension HTTPResponse: WireDataProviding {

    public func data() async throws -> Data {
        let data = try await body.readData()
        body = .data(data)
        return data ?? Data()
    }
}
