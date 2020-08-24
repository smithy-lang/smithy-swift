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

/**
 Mock URL protocol setup
 */
class TestURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
      // handles all requests
      return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
      return request
    }

    override func startLoading() {
      guard let handler = TestURLProtocol.requestHandler else {
        fatalError("Handler is unavailable.")
      }

      do {
        let (response, data) = try handler(request)

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data = data {
          client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
      } catch {

        client?.urlProtocol(self, didFailWithError: error)
      }
    }

    override func stopLoading() {
      print("Network task is cancelled.")
    }
}
