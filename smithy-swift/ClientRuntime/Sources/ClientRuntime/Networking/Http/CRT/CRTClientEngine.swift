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

import AwsCommonRuntimeKit

public class CRTClientEngine: HttpClientEngine {
    private let connectionMgr: HttpClientConnectionManager
    
    public init(options: HttpClientConnectionOptions) {
        connectionMgr = HttpClientConnectionManager(options: options)
    }
    
    public func execute(request: AsyncRequest, completion: @escaping NetworkResult) throws {
        let connection = try connectionMgr.acquireConnection().get()
        let requestOptions = HttpRequestOptions(request: request.toHttpRequest()) { (stream, headerBlock, httpHeaders) in
            print(stream)
        } onIncomingHeadersBlockDone: { (stream, headerBlock) in
            print(headerBlock)
        } onIncomingBody: { (stream, data) in
            print(data)
        } onStreamComplete: { (stream, errorCode) in
            print(stream)
        }

        connection.makeRequest(requestOptions: requestOptions)
    }
    
    public func close() {
        connectionMgr.closePendingConnections()
    }
}
