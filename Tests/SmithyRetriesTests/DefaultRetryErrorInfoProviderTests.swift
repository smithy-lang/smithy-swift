//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI
import Foundation
import XCTest
@testable import ClientRuntime

final class DefaultRetryErrorInfoProviderTests: XCTestCase {

    // MARK: - HTTPError

    func test_returnsErrorInfoWhenErrorIsARetryableHTTPStatusCode() {

        struct RetryableHTTPError: Error, HTTPError {
            let httpResponse: HttpResponse

            init(statusCode: HttpStatusCode) {
                self.httpResponse = HttpResponse(headers: Headers(), statusCode: statusCode)
            }
        }

        XCTAssertEqual(
            DefaultRetryErrorInfoProvider.errorInfo(for: RetryableHTTPError(statusCode: .internalServerError)),
            .init(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
        )
        XCTAssertEqual(
            DefaultRetryErrorInfoProvider.errorInfo(for: RetryableHTTPError(statusCode: .badGateway)),
            .init(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
        )
        XCTAssertEqual(
            DefaultRetryErrorInfoProvider.errorInfo(for: RetryableHTTPError(statusCode: .serviceUnavailable)),
            .init(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
        )
        XCTAssertEqual(
            DefaultRetryErrorInfoProvider.errorInfo(for: RetryableHTTPError(statusCode: .gatewayTimeout)),
            .init(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
        )
    }

    // MARK: - Modeled errors

    func test_returnsErrorInfoWhenErrorIsModeledRetryableAndFaultIsServer() {

        struct ModeledRetryableServerError: Error, ModeledError {
            static var typeName: String { "ModeledRetryableServerError" }
            static var fault: ClientRuntime.ErrorFault { .server }
            static var isRetryable: Bool { true }
            static var isThrottling: Bool { false }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledRetryableServerError())
        XCTAssertEqual(errorInfo, .init(errorType: .serverError, retryAfterHint: nil, isTimeout: false))
    }

    func test_returnsErrorInfoWhenErrorIsModeledRetryableAndFaultIsClient() {

        struct ModeledRetryableClientError: Error, ModeledError {
            static var typeName: String { "ModeledRetryableClientError" }
            static var fault: ClientRuntime.ErrorFault { .client }
            static var isRetryable: Bool { true }
            static var isThrottling: Bool { false }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledRetryableClientError())
        XCTAssertEqual(errorInfo, .init(errorType: .clientError, retryAfterHint: nil, isTimeout: false))
    }

    func test_returnsErrorInfoWhenErrorIsModeledRetryableThrottlingAndFaultIsServer() {

        struct ModeledThrottlingServerError: Error, ModeledError {
            static var typeName: String { "ModeledThrottlingServerError" }
            static var fault: ClientRuntime.ErrorFault { .server }
            static var isRetryable: Bool { true }
            static var isThrottling: Bool { true }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledThrottlingServerError())
        XCTAssertEqual(errorInfo, .init(errorType: .throttling, retryAfterHint: nil, isTimeout: false))
    }

    func test_returnsErrorInfoWhenErrorIsModeledRetryableThrottlingAndFaultIsClient() {

        struct ModeledThrottlingClientError: Error, ModeledError {
            static var typeName: String { "ModeledThrottlingClientError" }
            static var fault: ClientRuntime.ErrorFault { .server }
            static var isRetryable: Bool { true }
            static var isThrottling: Bool { true }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledThrottlingClientError())
        XCTAssertEqual(errorInfo, .init(errorType: .throttling, retryAfterHint: nil, isTimeout: false))
    }

    func test_returnsNilWhenErrorIsServerAndNotRetryableNotThrottling() {

        struct ModeledServerError: Error, ModeledError {
            static var typeName: String { "ModeledServerError" }
            static var fault: ClientRuntime.ErrorFault { .server }
            static var isRetryable: Bool { false }
            static var isThrottling: Bool { false }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledServerError())
        XCTAssertEqual(errorInfo, nil)
    }

    func test_returnsNilWhenErrorIsClientAndNotRetryableNotThrottling() {

        struct ModeledClientError: Error, ModeledError {
            static var typeName: String { "ModeledClientError" }
            static var fault: ClientRuntime.ErrorFault { .client }
            static var isRetryable: Bool { false }
            static var isThrottling: Bool { false }
        }

        let errorInfo = DefaultRetryErrorInfoProvider.errorInfo(for: ModeledClientError())
        XCTAssertEqual(errorInfo, nil)
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
