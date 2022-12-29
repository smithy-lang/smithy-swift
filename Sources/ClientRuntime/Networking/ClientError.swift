/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit

public enum ClientError: Error, Equatable {
    case networkError(Error)
    case crtError(CRTError)
    case pathCreationFailed(String)
    case queryItemCreationFailed(String)
    case serializationFailed(String)
    case deserializationFailed(Error)
    case dataNotFound(String)
    case unknownError(String)
    case authError(String)
    case retryError(Error)
    
    public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
        switch (lhs, rhs) {
        case let (.networkError(lhsError), .networkError(rhsError)):
            return String(reflecting: lhsError) == String(reflecting: rhsError)
        case let (.pathCreationFailed(lhsError), .pathCreationFailed(rhsError)):
            return lhsError == rhsError
        case let (.queryItemCreationFailed(lhsError), .queryItemCreationFailed(rhsError)):
            return lhsError == rhsError
        case let (.serializationFailed(lhsError), .serializationFailed(rhsError)):
            return lhsError == rhsError
        case let (.deserializationFailed(lhsError), .deserializationFailed(rhsError)):
            return String(reflecting: lhsError) == String(reflecting: rhsError)
        case let (.dataNotFound(lhsError), .dataNotFound(rhsError)):
            return lhsError == rhsError
        case let (.unknownError(lhsError), .unknownError(rhsError)):
            return lhsError == rhsError
        case let (.authError(lhsError), .authError(rhsError)):
            return lhsError == rhsError
        case let (.retryError(lhsError), .retryError(rhsError)):
            return String(reflecting: lhsError) == String(reflecting: rhsError)
        default:
            return false
        }
    }
}
