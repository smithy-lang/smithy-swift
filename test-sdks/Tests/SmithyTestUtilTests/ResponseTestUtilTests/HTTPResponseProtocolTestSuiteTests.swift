//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyTestUtil
import Testing

@Suite
struct HTTPResponseProtocolTestSuiteTests: EventStreamProtocolTestSuite {

    private struct ExpectedError: Error, Equatable { let code: Int }
    private struct OtherError: Error {}

    @Test
    func captureErrorReturnsTheExpectedError() async throws {
        let error = try await captureError(ExpectedError.self) { throw ExpectedError(code: 1) }
        #expect(error == ExpectedError(code: 1))
    }

    @Test
    func captureErrorThrowsHarnessErrorWhenOperationSucceeds() async throws {
        await #expect(throws: SmithyTestUtilError.self) {
            _ = try await captureError(ExpectedError.self) { 1 }
        }
    }

    @Test
    func captureErrorThrowsHarnessErrorForAnotherErrorType() async throws {
        await #expect(throws: SmithyTestUtilError.self) {
            _ = try await captureError(ExpectedError.self) { throw OtherError() }
        }
    }

    @Test
    func sdkErrorDoesNotMistakeHarnessErrorsForSDKErrors() async throws {
        // A harness failure inside `sdkError` must fail the test, not count as the expected SDK error.
        await #expect(throws: SmithyTestUtilError.self) {
            _ = try await sdkError {
                _ = try await captureRequest { 1 }
            }
        }
    }
}
