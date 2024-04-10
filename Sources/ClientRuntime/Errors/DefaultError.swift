/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import ClientRuntime

/// A general Error Structure for Rest JSON protocol
public struct DefaultError {
    public let errorMessage: String?
    public let errorType: String?

    public init(httpResponse: HttpResponse) async throws {
        var message: String? = nil
        var errorType: String? = nil
        if let data = try await httpResponse.body.readData() {
            let output: DefaultErrorPayload = try JSONDecoder().decode(responseBody: data)
            message = output.message
            errorType = output.errorType
        }
        self.errorMessage = message
        self.errorType = errorType
    }
}


