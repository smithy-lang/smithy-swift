//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import Foundation
import ClientRuntime
import XCTest

/**
 Includes Utility functions for Http Protocol Response Deserialization Tests
 */
open class HttpResponseTestBase: XCTestCase {
    /**
     Create `HttpResponse` from its components
     */
    public func buildHttpResponse(code: Int,
                                  path: String? = nil,
                                  headers: [String: String]? = nil,
                                  content: ResponseType? = nil,
                                  host: String) -> HttpResponse? {
        
        var internalHeaders: Headers = Headers()
        if let headers = headers {
            internalHeaders = Headers(headers)
        }
        
        return HttpResponse(headers: internalHeaders,
                            content: content,
                            statusCode: HttpStatusCode(rawValue: code) ?? HttpStatusCode.badRequest)
        
    }
}
