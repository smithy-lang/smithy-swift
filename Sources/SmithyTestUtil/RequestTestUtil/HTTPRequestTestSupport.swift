//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Smithy
import SmithyHTTPAPI

/// Test-framework-independent implementation of HTTP request protocol test helpers.
///
/// Used by both `HttpRequestTestBase` (XCTest) and `HTTPRequestProtocolTestSuite` (Swift Testing).
enum HTTPRequestTestSupport {

    // MARK: - Building the expected request

    // swiftlint:disable:next function_parameter_count
    static func buildExpectedHttpRequest(
        method: HTTPMethodType,
        path: String,
        headers: [String: String]?,
        forbiddenHeaders: [String]?,
        requiredHeaders: [String]?,
        queryParams: [String]?,
        forbiddenQueryParams: [String]?,
        requiredQueryParams: [String]?,
        body: ByteStream?,
        host: String,
        resolvedHost: String?
    ) -> ExpectedSdkHttpRequest {
        let builder = ExpectedSdkHttpRequestBuilder()
        builder.withMethod(method)

        if let deconflictedHost = deconflictHost(host: host, resolvedHost: resolvedHost) {
            builder.withHost(deconflictedHost)
        }
        builder.withPath(path)

        queryItems(queryParams).forEach { builder.withQueryItem($0) }
        queryItems(forbiddenQueryParams).forEach { builder.withForbiddenQueryItem($0) }
        queryItems(requiredQueryParams).forEach { builder.withRequiredQueryItem($0) }

        for (headerName, headerValue) in headers ?? [:] {
            builder.withHeader(name: headerName, value: headerValue)
        }
        for headerName in forbiddenHeaders ?? [] {
            builder.withForbiddenHeader(name: headerName)
        }
        for headerName in requiredHeaders ?? [] {
            builder.withRequiredHeader(name: headerName)
        }

        if let body {
            builder.withBody(body)
        }

        return builder.build()
    }

    static func deconflictHost(host: String, resolvedHost: String?) -> String? {
        var deconflictedHost: String?
        if !host.isEmpty,
           let urlFromHost = URL(string: "http://\(host)"),
           let parsedHost = urlFromHost.host {
            deconflictedHost = parsedHost
        }
        if let resolvedHost = resolvedHost, !resolvedHost.isEmpty {
            deconflictedHost = resolvedHost
        }
        return deconflictedHost
    }

    static func queryItems(_ queryParams: [String]?) -> [URIQueryItem] {
        (queryParams ?? []).map(queryItem(_:))
    }

    /// Parses a query param in `name=value` or `name` form, as given in a Smithy protocol test.
    ///
    /// Only the first `=` separates the name from the value; any others are part of the value.
    static func queryItem(_ queryParam: String) -> URIQueryItem {
        let components = queryParam.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let value = components.count > 1 ? String(components[1]) : nil
        return URIQueryItem(name: String(components[0]), value: value)
    }

    // MARK: - Comparing requests

    static func assertEqual(
        _ expected: ExpectedSdkHttpRequest,
        _ actual: SmithyHTTPAPI.HTTPRequest,
        _ assertEqualHttpBody: ((ByteStream?, ByteStream?) async throws -> Void)?,
        reporter: TestFailureReporter
    ) async throws {
        assertRequest(
            actual,
            method: expected.method,
            path: expected.endpoint.uri.path,
            host: expected.endpoint.uri.host,
            headers: expected.headers,
            forbiddenHeaders: expected.forbiddenHeaders,
            requiredHeaders: expected.requiredHeaders,
            queryItems: expected.queryItems,
            forbiddenQueryItems: expected.forbiddenQueryItems,
            requiredQueryItems: expected.requiredQueryItems,
            reporter: reporter
        )

        // assert the contents of ByteStream match, if no body was on the test, no assertions are to be made about the body
        // https://smithy.io/2.0/additional-specs/http-protocol-compliance-tests.html#smithy-test-httprequesttests-trait
        try await assertEqualHttpBody?(expected.body, actual.body)
    }

    /// Checks each passed expectation against the actual request.  Expectations that are `nil` are not checked.
    static func assertRequest(
        _ actual: SmithyHTTPAPI.HTTPRequest,
        method: HTTPMethodType?,
        path: String?,
        host: String?,
        headers: Headers?,
        forbiddenHeaders: [String]?,
        requiredHeaders: [String]?,
        queryItems: [URIQueryItem]?,
        forbiddenQueryItems: [URIQueryItem]?,
        requiredQueryItems: [URIQueryItem]?,
        reporter: TestFailureReporter
    ) {
        assertHttpHeaders(headers, actual.headers, reporter: reporter)
        assertForbiddenHeaders(forbiddenHeaders, actual.headers, reporter: reporter)
        assertRequiredHeaders(requiredHeaders, actual.headers, reporter: reporter)
        assertQueryItems(queryItems, actual.queryItems, reporter: reporter)
        if let path { reporter.checkEqual(path, actual.destination.path, "Request path") }
        if let host { reporter.checkEqual(host, actual.destination.host, "Request host") }
        if let method { reporter.checkEqual(method, actual.method, "Request method") }
        assertForbiddenQueryItems(forbiddenQueryItems, actual.queryItems, reporter: reporter)
        assertRequiredQueryItems(requiredQueryItems, actual.queryItems, reporter: reporter)
    }

    static func genericAssertEqualHttpBodyData(
        expected: ByteStream,
        actual: ByteStream,
        contentType: HTTPBodyContentType,
        reporter: TestFailureReporter
    ) async throws {
        let expectedData = try await expected.readData()
        let actualData = try await actual.readData()

        // Unseekable streams may have already been read by Signer middleware and cannot be read again
        // Compare stream lengths if ByteStream is a .stream and actualData is nil
        if checkStreamLengthEqualityIfUnseekableActualStreamHasBeenRead(
            expected: expected, actual: actual, reporter: reporter
        ) {
            // Stream lengths were checked and comparing data will result in failure due to above conditions
            return
        }

        compareData(contentType: contentType, expectedData, actualData, reporter: reporter)
    }

    static func assertEqualHttpBodies(
        expected: ByteStream?,
        actual: ByteStream?,
        contentType: HTTPBodyContentType,
        reporter: TestFailureReporter
    ) async throws {
        guard let expected else {
            reporter.fail("The expected ByteStream is nil")
            return
        }
        guard let actual else {
            reporter.fail("The actual ByteStream is nil")
            return
        }
        try await genericAssertEqualHttpBodyData(
            expected: expected, actual: actual, contentType: contentType, reporter: reporter
        )
    }

    private static func checkStreamLengthEqualityIfUnseekableActualStreamHasBeenRead(
        expected: ByteStream,
        actual: ByteStream,
        reporter: TestFailureReporter
    ) -> Bool {
        guard case .stream(let actualStream) = actual,
              actualStream.position == actualStream.length, !actualStream.isSeekable,
              case .stream(let expectedStream) = expected else {
            return false // This is only applicable to unseekable streams that have been read
        }
        if actualStream.length == expectedStream.length {
            return true // Streams are considered equal
        }
        reporter.fail("Actual stream is a different size than expected!")
        return false
    }

    private static func compareData(
        contentType: HTTPBodyContentType,
        _ expected: Data?,
        _ actual: Data?,
        reporter: TestFailureReporter
    ) {
        switch (expected, actual) {
        case (let expected?, let actual?):
            assertBodyDataEqual(actual, expected, contentType: contentType, reporter: reporter)
        case (.some, nil):
            reporter.fail("actual data in ByteStream is nil but expected is not")
        case (nil, .some):
            reporter.fail("expected data in ByteStream is nil but actual is not")
        case (nil, nil):
            break // expected and actual bodies are both nil, no operation
        }
    }

    static func assertBodyDataEqual(
        _ actual: Data,
        _ expected: Data,
        contentType: HTTPBodyContentType?,
        reporter: TestFailureReporter
    ) {
        let isEqual: Bool
        do {
            isEqual = try bodyData(actual, matches: expected, contentType: contentType)
        } catch {
            reporter.fail("Failed to evaluate \(contentType.map { "\($0)" } ?? "") body with error: \(error)")
            return
        }
        if !isEqual {
            let expectedStr = String(data: expected, encoding: .utf8) ?? "<not UTF-8>"
            let actualStr = String(data: actual, encoding: .utf8) ?? "<not UTF-8>"
            reporter.fail("\nActual: \(actualStr)\nExpected: \(expectedStr)")
        }
    }

    /// Compares a body to the expected body, in the passed format.
    ///
    /// JSON, XML, form URL, and CBOR bodies are compared structurally.  If no content type is given,
    /// the bodies are compared byte-for-byte.
    static func bodyData(_ actual: Data, matches expected: Data, contentType: HTTPBodyContentType?) throws -> Bool {
        // CBOR is always compared structurally; other formats are equal if their bytes are equal.
        if contentType != .cbor && actual == expected { return true }
        switch contentType {
        case .xml:
            return XMLComparator.xmlData(actual, isEqualTo: expected)
        case .json:
            return try JSONComparator.jsonData(actual, isEqualTo: expected)
        case .formURL:
            return FormURLComparator.formURLData(actual, isEqualTo: expected)
        case .cbor:
            return try CBORComparator.cborData(actual, isEqualTo: expected)
        case nil:
            return false
        }
    }

    // MARK: - Comparing headers

    static func assertHttpHeaders(_ expected: Headers?, _ actual: Headers?, reporter: TestFailureReporter) {
        guard let expected = expected else {
            return
        }

        guard let actual = actual else {
            reporter.fail("There are expected headers and no actual headers.")
            return
        }

        expected.headers.forEach { header in
            reporter.check(actual.exists(name: header.name), "Header '\(header.name)' does not exist")

            guard actual.values(for: header.name) != header.value else {
                return
            }

            let actualValue = actual.values(for: header.name)?
                .joined(separator: ", ")
                .components(separatedBy: .whitespaces)
                .joined()

            reporter.check(actualValue != nil, "The actual header value for \(header.name) is not present")

            let expectedValue = header.value
                .joined(separator: ", ")
                .components(separatedBy: .whitespaces)
                .joined()

            reporter.check(
                actualValue == expectedValue,
                "Actual header '\(header.name)': '\(String(describing: actualValue))') " +
                "Expected header: '\(String(describing: expectedValue))'"
            )
        }
    }

    static func assertForbiddenHeaders(_ expected: [String]?, _ actual: Headers, reporter: TestFailureReporter) {
        for forbiddenHeaderName in expected ?? [] {
            reporter.check(
                !actual.exists(name: forbiddenHeaderName),
                """
                forbidden header found: \(forbiddenHeaderName):
                \(String(describing: actual.value(for: forbiddenHeaderName)))
                """
            )
        }
    }

    static func assertRequiredHeaders(_ expected: [String]?, _ actual: Headers, reporter: TestFailureReporter) {
        for requiredHeaderName in expected ?? [] {
            reporter.check(
                actual.exists(name: requiredHeaderName),
                """
                required header not found: \(requiredHeaderName):
                \(String(describing: actual.value(for: requiredHeaderName)))
                """
            )
        }
    }

    // MARK: - Comparing query items

    static func assertQueryItems(
        _ expected: [URIQueryItem]?,
        _ actual: [URIQueryItem]?,
        reporter: TestFailureReporter
    ) {
        guard let expectedQueryItems = expected else {
            return
        }
        guard let actualQueryItems = actual else {
            reporter.fail("actual query items in Endpoint is nil but expected are not")
            return
        }

        for expectedQueryItem in expectedQueryItems {
            let values = actualQueryItems.filter { $0.name == expectedQueryItem.name }.map { $0.value }
            reporter.check(
                values.contains(expectedQueryItem.value),
                """
                expected query item value not found for \"\(expectedQueryItem.name)\".
                Expected Value: \(expectedQueryItem.value ?? "nil")
                Actual Values: \(values)
                """
            )
        }
    }

    static func assertForbiddenQueryItems(
        _ expected: [URIQueryItem]?,
        _ actual: [URIQueryItem]?,
        reporter: TestFailureReporter
    ) {
        guard let forbiddenQueryItems = expected, let actualQueryItems = actual else {
            return
        }

        for forbiddenQueryItem in forbiddenQueryItems {
            // Per the Smithy spec, forbidden query params are names; no item with the name may appear.
            reporter.check(
                !actualQueryItems.contains { $0.name == forbiddenQueryItem.name },
                "forbidden query parameter found: \(forbiddenQueryItem.name)"
            )
        }
    }

    static func assertRequiredQueryItems(
        _ expected: [URIQueryItem]?,
        _ actual: [URIQueryItem]?,
        reporter: TestFailureReporter
    ) {
        guard let requiredQueryItems = expected else {
            return
        }
        guard let actualQueryItems = actual else {
            reporter.fail("actual query items in Endpoint is nil but required are not")
            return
        }

        for requiredQueryItem in requiredQueryItems {
            // Per the Smithy spec, required query params are names; an item with the name must appear.
            reporter.check(
                actualQueryItems.contains { $0.name == requiredQueryItem.name },
                "required query parameter not found: \(requiredQueryItem.name)"
            )
        }
    }
}
