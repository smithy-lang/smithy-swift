//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public enum MockMiddlewareError: Error {
    case unknown(Error)
}

extension MockMiddlewareError: HttpResponseBinding {
    public init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder?) throws {
        self = .unknown(ClientError.unknownError(httpResponse.debugDescription))
    }
}
