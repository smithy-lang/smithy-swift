/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Smithy
import SmithyHTTPAPI
import Foundation
import ClientRuntime
import XCTest
import class AwsCommonRuntimeKit.ByteBuffer

/**
 Includes Utility functions for Http Protocol Response Deserialization Tests
 */
open class HttpResponseTestBase: XCTestCase {
    /**
     Create `HTTPResponse` from its components
     */
    public func buildHttpResponse(code: Int,
                                  path: String? = nil,
                                  headers: [String: String]? = nil,
                                  content: ByteStream?) -> HTTPResponse? {

        var internalHeaders: Headers = Headers()
        if let headers = headers {
            internalHeaders = Headers(headers)
        }

        return HTTPResponse(headers: internalHeaders,
                            body: content ?? .noStream,
                            statusCode: HTTPStatusCode(rawValue: Int(code)) ?? HTTPStatusCode.badRequest)

    }
}
