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
 Includes Utility functions for Http Protocol Response DeSerialization Tests
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
        let urlString: String
        if let path = path {
            urlString = host + path
        } else {
            urlString = host
        }
        
        guard let url = URL(string: urlString) else {
            XCTFail("Failed to construct URL for HttpURLResponse")
            return nil
        }
        
        guard let httpUrlResponse = HTTPURLResponse(url: url,
                                                    statusCode: code,
                                                    httpVersion: "1.1",
                                                    headerFields: headers) else {
            XCTFail("Failed to construct HttpURLResponse")
            return nil
        }
        
        return HttpResponse(httpUrlResponse: httpUrlResponse, content: content)
    }
}
