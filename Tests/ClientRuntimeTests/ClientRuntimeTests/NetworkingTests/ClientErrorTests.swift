/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
import AwsCommonRuntimeKit
@testable import ClientRuntime

class ClientErrorTests: XCTestCase {
    
    func testNetworkErrorInEqualityWithoutDescription() throws {
        enum NetworkError: Error {
            case actual
            case expected
        }
        let actualNetworkError = ClientError.networkError(NetworkError.actual)
        let expectedNetworkError = ClientError.networkError(NetworkError.expected)
        
        XCTAssertNotEqual(actualNetworkError, expectedNetworkError)
    }
    
    func testNetworkErrorInEqualityWithDescription() throws {
        enum NetworkError: Error, CustomStringConvertible {
            case actual
            case expected

            var description: String {
                switch self {
                case .actual:
                    return "Actual"
                case .expected:
                    return "Expected"
                }
            }
        }
        
        let actualNetworkError = ClientError.networkError(NetworkError.actual)
        let expectedNetworkError = ClientError.networkError(NetworkError.expected)
        
        XCTAssertNotEqual(actualNetworkError, expectedNetworkError)
    }
    
    func testNetworkErrorEqualityWithDescription() throws {
        enum NetworkError: Error, CustomStringConvertible {
            case actual
            case actualCopy

            var description: String {
                switch self {
                case .actual:
                    return "Actual"
                case .actualCopy:
                    return "Actual"
                }
            }
        }
        
        let actualNetworkError = ClientError.networkError(NetworkError.actual)
        let actualCopyNetworkError = ClientError.networkError(NetworkError.actualCopy)
        
        XCTAssertEqual(actualNetworkError, actualCopyNetworkError)
    }

    // MARK: - WaiterTypedError protocol

    func test_waiterErrorType_returnsErrorTypeForWaitableNetworkError() async throws {
        let networkError = WaitableError()
        let subject = ClientError.networkError(networkError)
        XCTAssertEqual(subject.waiterErrorType, networkError.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForNonWaitableNetworkError() async throws {
        let networkError = NonWaitableError()
        let subject = ClientError.networkError(networkError)
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsErrorTypeForWaitableDeserializationError() async throws {
        let deserializationError = WaitableError()
        let subject = ClientError.deserializationFailed(deserializationError)
        XCTAssertEqual(subject.waiterErrorType, deserializationError.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForNonWaitableDeserializationError() async throws {
        let deserializationError = NonWaitableError()
        let subject = ClientError.deserializationFailed(deserializationError)
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsErrorTypeForWaitableRetryError() async throws {
        let retryError = WaitableError()
        let subject = ClientError.retryError(retryError)
        XCTAssertEqual(subject.waiterErrorType, retryError.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForNonWaitableRetryError() async throws {
        let retryError = NonWaitableError()
        let subject = ClientError.retryError(retryError)
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForCRTError() async throws {
        let crtError = CRTError(code: 2)
        let subject = ClientError.crtError(crtError)
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForPathCreationFailedError() async throws {
        let subject = ClientError.pathCreationFailed("path creation failed error")
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForQueryItemCreationFailedError() async throws {
        let subject = ClientError.queryItemCreationFailed("query item creation failed error")
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForSerializationFailedError() async throws {
        let subject = ClientError.serializationFailed("serialization failed error")
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForDataNotFoundError() async throws {
        let subject = ClientError.dataNotFound("data not found error")
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForUnknownError() async throws {
        let subject = ClientError.unknownError("unknown error")
        XCTAssertNil(subject.waiterErrorType)
    }

    func test_waiterErrorType_returnsNilForAuthError() async throws {
        let subject = ClientError.authError("auth error")
        XCTAssertNil(subject.waiterErrorType)
    }
}

// MARK: - Helper types

fileprivate struct WaitableError: WaiterTypedError {

    public var waiterErrorType: String? { "WaitableType" }
}

fileprivate struct NonWaitableError: Error {}
