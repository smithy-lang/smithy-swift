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

public protocol HttpSerialize {
  func encode() throws -> HttpRequest?
}

public extension HttpSerialize {
    /// Convenience function to encode an `Encodable` type as the request body, using the encoder provided.
    /// - Parameter obj: The value to encode
    /// - Parameter encoder: Instance of a RequestEncoder
    /// - throws: If the value cannot be encoded.
    func encodeBody<T: Encodable>(_ obj: T, encoder: RequestEncoder) throws -> HttpBody {
        if let data = obj as? Data {
            return HttpBody.data(data)
        }
        else {
            do {
                let data = try encoder.encodeRequest(obj)
                return HttpBody.data(data)
            }
            catch {
                throw ClientError.serializationFailed("Failed to Encode Http Request body")
            }
        }
    }
}



