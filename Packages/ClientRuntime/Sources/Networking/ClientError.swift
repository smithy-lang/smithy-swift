/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit

public enum ClientError: Error, Equatable {
    case networkError(Error)
    case crtError(CRTError)
    case pathCreationFailed(String)
    case serializationFailed(String)
    case deserializationFailed(Error)
    case dataNotFound(String)
    case unknownError(String)
    case authError(String)
    case maximumRetryAttemptsError(Int, Error)
    
    public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
        switch (lhs, rhs) {
        case (let .networkError(lhsNetworkError),
              let .networkError(rhsNetworkError)):
            return String(reflecting: lhsNetworkError) == String(reflecting: rhsNetworkError)
        case (let .pathCreationFailed(lhsPathError),
              let .pathCreationFailed(rhsPathError)):
            return lhsPathError == rhsPathError
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
        case (let .maximumRetryAttemptsError(lhsMaxRetries, lhsRetryError),
              let .maximumRetryAttemptsError(rhsMaxRetries, rhsRetryError)):
            return lhsMaxRetries == rhsMaxRetries &&
                String(reflecting: lhsRetryError) == String(reflecting: rhsRetryError)
        default:
            return false
        }
    }
}
