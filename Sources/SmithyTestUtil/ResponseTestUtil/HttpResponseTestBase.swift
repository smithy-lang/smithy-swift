/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import ClientRuntime
import Foundation
import Smithy
import SmithyHTTPAPI
import XCTest

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

        HTTPResponseTestSupport.buildHttpResponse(code: code, headers: headers, content: content)
    }
}
