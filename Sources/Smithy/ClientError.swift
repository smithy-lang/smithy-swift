//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum ClientError: Error {
    case serializationFailed(String)
    case dataNotFound(String)
    case unknownError(String)
    case authError(String)
}
