//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HTTPResponse

/// Filter additional information from error name and sanitize it.
///
/// Reference: https://smithy.io/2.0/aws/protocols/aws-restjson1-protocol.html#operation-error-serialization
func sanitizeErrorType(_ type: String) -> String {
    return type.substringAfter("#").substringBefore(":").trim()
}

public extension HTTPResponse {

    /// The request ID from the response headers: the value of the `x-amz-request-id` header, used by S3 and other
    /// REST services, else of the `x-amzn-RequestId` header, used by most other AWS services.
    var requestID: String? {
        return headers.value(for: "x-amz-request-id") ?? headers.value(for: "x-amzn-RequestId")
    }

    /// The value of the x-amz-id-2 header.
    var requestID2: String? {
        return headers.value(for: "x-amz-id-2")
    }
}
