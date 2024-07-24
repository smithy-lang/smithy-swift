//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum AWSSignedBodyValue {
    case empty
    case emptySha256
    case unsignedPayload
    case streamingSha256Payload
    case streamingSha256Events
    case streamingSha256PayloadTrailer
    case streamingUnsignedPayloadTrailer
    case precomputed(String)
}
