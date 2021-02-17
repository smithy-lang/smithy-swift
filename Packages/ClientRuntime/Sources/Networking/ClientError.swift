/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public enum ClientError: Error, Equatable {
    case networkError(Error)
    case serializationFailed(String)
    case deserializationFailed(Error)
    case dataNotFound(String)
    case unknownError(String)
    
    public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
        switch (lhs, rhs) {
        case (let .networkError(lhsNetworkError),
              let .networkError(rhsNetworkError)):
            return String(reflecting: lhsNetworkError) == String(reflecting: rhsNetworkError)
        case (let .serializationFailed(lhsSerializationFailedString),
              let .serializationFailed(rhsSerializationFailedString)):
            return lhsSerializationFailedString == rhsSerializationFailedString
        case (let .deserializationFailed(lhsDeserializationFailedError),
              let .deserializationFailed(rhsDeserializationFailedError)):
            return String(reflecting: lhsDeserializationFailedError)
                == String(reflecting: rhsDeserializationFailedError)
        case (let .dataNotFound(lhsDataNotFoundString),
              let .dataNotFound(rhsDataNotFoundString)):
            return lhsDataNotFoundString == rhsDataNotFoundString
        case (let .unknownError(lhsUnknownString),
              let .unknownError(rhsUnknownString)):
            return lhsUnknownString == rhsUnknownString
        default:
            return false
        }
    }
}
