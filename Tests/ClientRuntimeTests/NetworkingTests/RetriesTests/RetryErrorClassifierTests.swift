//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import ClientRuntime

class RetryErrorClassifierTests: XCTestCase {

    func test_serviceError_isRetryableIfRetryableIsTrue() {
        let serviceError = TestServiceError(_retryable: true)
        let sdkError = sdkError(from: serviceError)
        let subject = RetryErrorClassifier<TestOutputError>({ _ in return nil })
        let errorInfo = subject.retryErrorInfo(error: sdkError)
        XCTAssertEqual(errorInfo?.errorType, .transient)
        XCTAssertEqual(errorInfo?.retryAfterHint, nil)
    }

    func test_serviceError_isThrottleableIfIsThrottlingIsTrue() {
        let serviceError = TestServiceError(_retryable: true, _isThrottling: true)
        let sdkError = sdkError(from: serviceError)
        let subject = RetryErrorClassifier<TestOutputError>({ _ in return nil })
        let errorInfo = subject.retryErrorInfo(error: sdkError)
        XCTAssertEqual(errorInfo?.errorType, .throttling)
        XCTAssertEqual(errorInfo?.retryAfterHint, nil)
    }

    private func sdkError(from serviceError: TestServiceError) -> SdkError<TestOutputError> {
        let outputError = TestOutputError.testServiceError(serviceError)
        return SdkError.service(outputError, httpResponse())
    }

    private func httpResponse() -> HttpResponse {
        let headers = Headers()
        let body = HttpBody.data(Data())
        let statusCode = HttpStatusCode.ok
        return HttpResponse(headers: headers, body: body, statusCode: statusCode)
    }
}


fileprivate enum TestOutputError: ServiceErrorProviding {
    case testServiceError(TestServiceError)

    var serviceError: ServiceError {
        switch self {
        case .testServiceError(let serviceError): return serviceError
        }
    }
}


fileprivate struct TestServiceError: ServiceError {
    var _retryable: Bool = false
    var _isThrottling: Bool = false
    var _type: ClientRuntime.ErrorType = .client
    var _message: String? = "This is an error message"
    static var _modelName: String { "TestServiceError" }
}
