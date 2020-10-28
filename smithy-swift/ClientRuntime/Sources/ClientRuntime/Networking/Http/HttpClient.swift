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

public class HttpClient {

    let session: SessionProtocol
    let operationQueue: OperationQueue

    public init(config: HttpClientConfiguration) {
        self.operationQueue = config.operationQueue
        let delegate = SessionDelegate(operationQueue: config.operationQueue)
        self.session = URLSession(configuration: config.toUrlSessionConfig(), delegate: delegate, delegateQueue: config.operationQueue)
    }

    public init(session: SessionProtocol, config: HttpClientConfiguration) {
        self.session = session
        self.operationQueue = config.operationQueue
    }

    public func execute(request: AsyncRequest, completion: @escaping NetworkResult) -> StreamingProvider? {
        switch request.body {
        case .data, .file, .none :
            guard let operation = try? DataNetworkOperation(session: session, request: request, completion: completion) else { return nil }
            operationQueue.addOperation(operation)
        case .stream:
            let streamingProvider = StreamingProvider()
            let operation = StreamingNetworkOperation(session: session, request: request, streamingProvider: streamingProvider, completion: completion)
            operationQueue.addOperation(operation)
            return streamingProvider
        }
        return nil
    }
}
