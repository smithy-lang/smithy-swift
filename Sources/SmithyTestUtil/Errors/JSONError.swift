/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import ClientRuntime

/// A general error structure for protocols with JSON response
public struct JSONError {
    public let errorMessage: String?
    public let errorType: String?

    public init(httpResponse: HttpResponse) async throws {
        var message: String?
        var errorType: String?
        if let data = try await httpResponse.body.readData() {
            let output: JSONErrorPayload = try JSONDecoder().decode(responseBody: data)
            message = output.message
            errorType = output.errorType
        }
        self.errorMessage = message
        self.errorType = errorType
    }
}
