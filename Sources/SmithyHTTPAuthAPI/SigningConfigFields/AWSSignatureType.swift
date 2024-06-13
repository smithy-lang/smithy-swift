//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum AWSSignatureType {
    case requestHeaders
    case requestQueryParams
    case requestChunk
    case requestTrailingHeaders
    case requestEvent
}
