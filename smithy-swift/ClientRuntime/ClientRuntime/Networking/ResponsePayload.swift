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

public struct ResponsePayload {
    public let body: Data
    public let decoder: ResponseDecoder
    
    public init(body: Data, decoder: ResponseDecoder) {
        self.body = body
        self.decoder = decoder
    }
    
    public func decode<T: Decodable>() -> Result<T, ClientError> {
        do {
            let result: T = try decoder.decodeResponse(responseBody: body)
            return .success(result)
        } catch let jsonErr {
            return .failure(ClientError.deserializationFailed(jsonErr))
        }
    }
}
