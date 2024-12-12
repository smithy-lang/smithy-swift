//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Additional logging opt-in for request / response flow. For each selected option other than `.none`, the additional info gets logged at `.debug` level by the `LoggingMiddleware`.
public enum ClientLogMode {
    case none
    case request
    case requestWithBody
    case response
    case responseWithBody
    case requestAndResponse
    case requestAndResponseWithBody
    case requestWithoutAuthorizationHeader
}
