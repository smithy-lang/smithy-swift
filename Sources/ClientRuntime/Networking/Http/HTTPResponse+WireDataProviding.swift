//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HttpResponse
import enum Smithy.ByteStream
import protocol SmithyReadWrite.WireDataProviding
import struct Foundation.Data

extension HttpResponse: WireDataProviding {

    public func data() async throws -> Data {
        let data = try await body.readData()
        body = .data(data)
        return data ?? Data()
    }
}
