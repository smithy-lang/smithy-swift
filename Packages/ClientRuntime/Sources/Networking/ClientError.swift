/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit

public enum ClientError: Error, Equatable {
    case networkError(Error)
    case crtError(CRTError)
    case serializationFailed(String)
    case deserializationFailed(Error)
    case dataNotFound(String)
    case unknownError(String)
    case authError(String)
    case retryError(Error)
    
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
        case (let .authError(lhsAuthString),
              let .authError(rhsAuthString)):
            return lhsAuthString == rhsAuthString
        case (let .retryError(lhsRetryError),
              let .retryError(rhsRetryError)):
            return String(reflecting: lhsRetryError) == String(reflecting: rhsRetryError)
        default:
            return false
        }
    }
}
