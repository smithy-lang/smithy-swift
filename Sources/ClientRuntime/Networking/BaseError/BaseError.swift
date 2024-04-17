//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol BaseError {
    var httpResponse: HttpResponse { get }
    var code: String { get }
    var message: String? { get }
    var requestID: String? { get }
}

public enum BaseErrorDecodeError: Error {
    case missingRequiredData
}
