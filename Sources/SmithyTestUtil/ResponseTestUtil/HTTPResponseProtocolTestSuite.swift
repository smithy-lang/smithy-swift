//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI

/// Helpers for Swift Testing-based HTTP protocol response deserialization tests.
///
/// Conform a Swift Testing suite to this protocol to use the helpers.  This is the Swift Testing
/// counterpart to the XCTest-based `HttpResponseTestBase`.
public protocol HTTPResponseProtocolTestSuite {}

public extension HTTPResponseProtocolTestSuite {

    /// Create an `HTTPResponse` from its components
    func buildHttpResponse(
        code: Int,
        headers: [String: String]? = nil,
        content: ByteStream?
    ) -> HTTPResponse {
        HTTPResponseTestSupport.buildHttpResponse(code: code, headers: headers, content: content)
    }

    /// Performs an operation that is expected to fail, and returns the error it threw.
    /// - Parameters:
    ///   - errorType: The type of error the operation is expected to throw.
    ///   - operation: The operation to perform.
    /// - Returns: The error thrown by the operation.
    /// - Throws: `SmithyTestUtilError` if the operation succeeds, or fails with an error of another type.
    func captureError<ExpectedError: Error, Output>(
        _ errorType: ExpectedError.Type,
        _ operation: () async throws -> Output
    ) async throws -> ExpectedError {
        do {
            _ = try await operation()
        } catch let error as ExpectedError {
            return error
        } catch let error as SmithyTestUtilError {
            throw error
        } catch {
            throw SmithyTestUtilError(
                "The deserialized error type does not match expected type.  " +
                "Expected: \(ExpectedError.self)  Actual: \(type(of: error)) \(error)"
            )
        }
        throw SmithyTestUtilError("Request should have failed with \(ExpectedError.self), but it succeeded")
    }
}

enum HTTPResponseTestSupport {

    static func buildHttpResponse(code: Int, headers: [String: String]?, content: ByteStream?) -> HTTPResponse {
        HTTPResponse(
            headers: headers.map { Headers($0) } ?? Headers(),
            body: content ?? .noStream,
            statusCode: HTTPStatusCode(rawValue: code) ?? .badRequest
        )
    }
}
