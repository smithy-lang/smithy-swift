//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public typealias WireResponseDocumentBinding<WireResponse: WireDataProviding, Reader: SmithyReader> =
    (WireResponse) async throws -> Reader

/// Creates a `WireResponseDocumentBinding` for converting a wire response into a `Reader`.
public func wireResponseDocumentBinding<WireResponse, Reader>() -> WireResponseDocumentBinding<WireResponse, Reader> {
    return { response in
        let data = try await response.data()
        return try Reader.from(data: data)
    }
}
