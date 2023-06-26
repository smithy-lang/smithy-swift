//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

final class DefaultRetryErrorInfoProviderTests: XCTestCase {

    // MARK: - Modeled errors

    func test_errorInfo_returnsServerWhenErrorIsModeledRetryableAndFaultIsServer() {

        struct ModeledServerError: Error, ModeledError {
            static var typeName: String { "ModeledServerError" }
            static var fault: ClientRuntime.ErrorFault { .server }
            static var isRetryable: Bool { true }
            static var isThrottling: Bool { false }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledServerError())
        XCTAssertEqual(errorInfo?.errorType, .serverError)
    }

    func test_errorInfo_returnsClientWhenErrorIsModeledRetryableAndFaultIsClient() {

        struct ModeledClientError: Error, ModeledError {
            static var typeName: String { "ModeledClientError" }
            static var fault: ClientRuntime.ErrorFault { .client }
            static var isRetryable: Bool { true }
            static var isThrottling: Bool { false }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledClientError())
        XCTAssertEqual(errorInfo?.errorType, .clientError)
    }

    func test_errorInfo_returnsThrottlingWhenErrorIsModeledRetryableThrottling() {

        struct ModeledThrottlingError: Error, ModeledError {
            static var typeName: String { "ModeledThrottlingError" }
            static var fault: ClientRuntime.ErrorFault { .server }
            static var isRetryable: Bool { true }
            static var isThrottling: Bool { true }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledThrottlingError())
        XCTAssertEqual(errorInfo?.errorType, .throttling)
    }

    // MARK: - Retry after hint

    func test_errorInfo_returnsRetryAfterDelayWhenRetryAfterHeaderIsSet() {

        struct RetryAfterError: Error, HTTPError {
            var httpResponse: HttpResponse = HttpResponse(headers: Headers(["x-retry-after": String(0.027)]), statusCode: .internalServerError)
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: RetryAfterError())
        XCTAssertEqual(errorInfo?.retryAfterHint, 0.027)
    }
}
