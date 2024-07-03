//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum ClientLogMode {
    case request
    case requestWithBody
    case response
    case responseWithBody
    case requestAndResponse
    case requestAndResponseWithBody
    case requestWithoutAuthorizationHeader
}
