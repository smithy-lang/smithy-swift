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

public protocol RequestEncoder {
    
    func encode<T>(_ value: T) throws -> Data where T: Encodable
    
    // Encodes the input object and sets it as body for currentRequest
    func encodeHttpRequest<T>(_ input: T, currentHttpRequest: inout HttpRequest) throws -> HttpRequest where T: Encodable
}

public extension RequestEncoder {
    
    func encodeHttpRequest<T>(_ input: T, currentHttpRequest: inout HttpRequest) throws -> HttpRequest where T: Encodable {
        if let data = input as? Data {
            currentHttpRequest.body = HttpBody.data(data)
            return currentHttpRequest
        } else {
            do {
                let data = try self.encode(input)
                currentHttpRequest.body = HttpBody.data(data)
                return currentHttpRequest
            } catch {
                throw ClientError.serializationFailed("Failed to Encode Http Request body")
            }
        }
    }
}
