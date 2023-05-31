/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit

public enum ClientError: Error {
    case pathCreationFailed(String)
    case queryItemCreationFailed(String)
    case serializationFailed(String)
    case dataNotFound(String)
    case unknownError(String)
    case authError(String)
}
