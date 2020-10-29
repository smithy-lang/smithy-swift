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

//class DataNetworkOperation: NetworkOperation {
//
//    init(session: SessionProtocol, request: AsyncRequest, completion: @escaping NetworkResult) {
//        super.init()
//        self.completion = completion
//        do {
//        let urlRequest = try request.toUrlRequest()
//        self.task = session.dataTask(with: urlRequest)
//        } catch {
//            completion(.failure(ClientError.serializationFailed("Serialization failed due to malformed url")))
//        }
//    }
//
//    override func receiveData(data: Data) {
//        response?.content = .data(data)
//        completion?(Result.success(response!))
//        self.state = .finished
//    }
//}

