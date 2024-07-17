//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI
import ClientRuntime

public enum MockMiddlewareError: Error {
    case unknown(Error)

    public static func responseErrorClosure(_ httpResponse: HTTPResponse) -> Error {
        return UnknownServiceError(typeName: "MockMiddlewareError", message: httpResponse.debugDescription)
    }
}

