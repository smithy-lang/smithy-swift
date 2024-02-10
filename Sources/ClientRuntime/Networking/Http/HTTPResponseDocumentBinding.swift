//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyXML.Reader

public typealias HTTPResponseDocumentBinding<Reader> = (HttpResponse) async throws -> Reader

/// Creates a `HTTPResponseDocumentBinding` for converting a HTTP response into a `Reader`.
public var responseDocumentBinding: HTTPResponseDocumentBinding<Reader> {
    return { response in
        let data = try await response.body.readData()
        response.body = .data(data)
        return try Reader.from(data: data ?? Data())
    }
}
