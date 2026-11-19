//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import Smithy
import SmithyHTTPAPI
import Testing

/// Helpers for Swift Testing-based HTTP protocol request serialization tests.
///
/// Conform a Swift Testing suite to this protocol to use the helpers.  This is the Swift Testing
/// counterpart to the XCTest-based `HttpRequestTestBase`.
public protocol HTTPRequestProtocolTestSuite {}

public extension HTTPRequestProtocolTestSuite {

    /// Create an `ExpectedSdkHttpRequest` from its components
    func buildExpectedHttpRequest(
        method: HTTPMethodType,
        path: String,
        headers: [String: String]? = nil,
        forbiddenHeaders: [String]? = nil,
        requiredHeaders: [String]? = nil,
        queryParams: [String]? = nil,
        forbiddenQueryParams: [String]? = nil,
        requiredQueryParams: [String]? = nil,
        body: ByteStream?,
        host: String,
        resolvedHost: String?
    ) -> ExpectedSdkHttpRequest {
        HTTPRequestTestSupport.buildExpectedHttpRequest(
            method: method,
            path: path,
            headers: headers,
            forbiddenHeaders: forbiddenHeaders,
            requiredHeaders: requiredHeaders,
            queryParams: queryParams,
            forbiddenQueryParams: forbiddenQueryParams,
            requiredQueryParams: requiredQueryParams,
            body: body,
            host: host,
            resolvedHost: resolvedHost
        )
    }

    /// Performs an operation on a client using `ProtocolTestClient`, and returns the request that the client sent.
    ///
    /// `ProtocolTestClient` throws the request it receives rather than sending it; this captures that request.
    /// Any other error thrown by the operation is rethrown.
    /// - Throws: `SmithyTestUtilError` if the operation completes without sending a request.
    /// - Parameter operation: The operation to perform.
    /// - Returns: The request sent by the operation.
    func captureRequest<Output>(_ operation: () async throws -> Output) async throws -> SmithyHTTPAPI.HTTPRequest {
        do {
            _ = try await operation()
        } catch TestCheckError.actual(let request) {
            return request
        }
        throw SmithyTestUtilError("Operation completed without sending a request to the protocol test client")
    }

    /// Records an issue for each way in which the actual request does not match the expected request.
    /// - Parameters:
    ///   - expected: The expected request
    ///   - actual: The actual request to compare against
    ///   - bodyContentType: The format to compare bodies in.  If `nil`, bodies are not compared.
    func assertEqual(
        _ expected: ExpectedSdkHttpRequest,
        _ actual: SmithyHTTPAPI.HTTPRequest,
        bodyContentType: HTTPBodyContentType? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) async throws {
        let sourceLocation = SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
        let reporter = TestFailureReporter.swiftTesting(sourceLocation)
        let assertEqualHttpBody = bodyContentType.map { contentType in
            { (expectedBody: ByteStream?, actualBody: ByteStream?) in
                try await HTTPRequestTestSupport.assertEqualHttpBodies(
                    expected: expectedBody, actual: actualBody, contentType: contentType, reporter: reporter
                )
            }
        }
        try await HTTPRequestTestSupport.assertEqual(expected, actual, assertEqualHttpBody, reporter: reporter)
    }

    /// Records an issue for each passed expectation that the actual request does not meet.
    ///
    /// Expectations that are not passed are not checked.  Headers, query params & bodies are compared
    /// the same way as `assertEqual(_:_:bodyContentType:)` compares them.
    /// - Parameters:
    ///   - actual: The actual request to check.
    ///   - method: The expected HTTP method.
    ///   - path: The expected path.
    ///   - host: The expected host.
    ///   - headers: Headers that must be present, with the passed values.
    ///   - forbiddenHeaders: Names of headers that must not be present.
    ///   - requiredHeaders: Names of headers that must be present, with any value.
    ///   - queryParams: Query params, in `name=value` or `name` form, that must be present.
    ///   - forbiddenQueryParams: Names of query params that must not be present.
    ///   - requiredQueryParams: Names of query params that must be present, with any value.
    ///   - body: The expected body.
    ///   - bodyMediaType: The media type of the body, which determines how the body is compared.
    func assertRequest(
        _ actual: SmithyHTTPAPI.HTTPRequest,
        method: HTTPMethodType? = nil,
        path: String? = nil,
        host: String? = nil,
        headers: [String: String]? = nil,
        forbiddenHeaders: [String]? = nil,
        requiredHeaders: [String]? = nil,
        queryParams: [String]? = nil,
        forbiddenQueryParams: [String]? = nil,
        requiredQueryParams: [String]? = nil,
        body: Data? = nil,
        bodyMediaType: String? = nil,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) async throws {
        let sourceLocation = SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
        let reporter = TestFailureReporter.swiftTesting(sourceLocation)
        HTTPRequestTestSupport.assertRequest(
            actual,
            method: method,
            path: path,
            host: host,
            headers: headers.map { Headers($0) },
            forbiddenHeaders: forbiddenHeaders,
            requiredHeaders: requiredHeaders,
            queryItems: queryParams.map(HTTPRequestTestSupport.queryItems(_:)),
            forbiddenQueryItems: forbiddenQueryParams.map(HTTPRequestTestSupport.queryItems(_:)),
            requiredQueryItems: requiredQueryParams.map(HTTPRequestTestSupport.queryItems(_:)),
            reporter: reporter
        )
        if let body {
            let actualBody = try await actual.body.readData() ?? Data()
            HTTPRequestTestSupport.assertBodyDataEqual(
                actualBody, body, contentType: HTTPBodyContentType(mediaType: bodyMediaType), reporter: reporter
            )
        }
    }
}
