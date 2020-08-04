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

public enum ClientError: Error, Equatable {
    case networkError(String)
    case serializationFailed(String)
    case deserializationFailed(Error)
    case dataNotFound(String)
    
    public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
        switch (lhs, rhs) {
        case (let .networkError(lhsNetworkErrorString), let .networkError(rhsNetworkErrorString)):
            return lhsNetworkErrorString == rhsNetworkErrorString
        case (let .serializationFailed(lhsSerializationFailedString), let .serializationFailed(rhsSerializationFailedString)):
            return lhsSerializationFailedString == rhsSerializationFailedString
        case (let .deserializationFailed(lhsDeserializationFailedError), let .deserializationFailed(rhsDeserializationFailedError)):
            return lhsDeserializationFailedError.localizedDescription == rhsDeserializationFailedError.localizedDescription
        case (let .dataNotFound(lhsDataNotFoundString), let .dataNotFound(rhsDataNotFoundString)):
            return lhsDataNotFoundString == rhsDataNotFoundString
        default:
            return false
        }
    }
}
