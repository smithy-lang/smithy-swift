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
@testable import ClientRuntime

class MockURLSession: SessionProtocol {
    var nextDataTask = MockURLSessionDataTask()
    var nextData: Data?
    var nextError: Error?
    
    private (set) var lastURL: URL?
    
    func successHttpURLResponse(request: URLRequest) -> URLResponse {
        return HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
    }
    
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        lastURL = request.url
        
        completionHandler(nextData, successHttpURLResponse(request: request), nextError)
        return nextDataTask
    }
    
    func dataTask(with request: URLRequest) -> URLSessionDataTaskProtocol {
        lastURL = request.url
        return nextDataTask
    }
    
    func uploadTask(withStreamedRequest request: URLRequest) -> URLSessionUploadTask {
        // TODO
        return URLSessionUploadTask()
    }
}

class MockURLSessionDataTask: URLSessionTask, URLSessionDataTaskProtocol {
    private (set) var resumeWasCalled = false
    
    override func resume() {
        resumeWasCalled = true
    }
    
    override init() {
        
    }
}
