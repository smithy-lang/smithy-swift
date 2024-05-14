//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import ClientRuntime
import XCTest

/**
 Includes Utility functions for Http Protocol Request Serialization Tests
 */
public typealias ValidateCallback = (Data, Data) -> Void

public enum HTTPBodyContentType {
    case xml
    case json
    case formURL
}

open class HttpRequestTestBase: XCTestCase {

    open override func setUp() {
        CommonRuntimeKit.initialize()
    }

    /**
     Create `HttpRequest` from its components
     */
    public func buildExpectedHttpRequest(method: HttpMethodType,
                                         path: String,
                                         headers: [String: String]? = nil,
                                         forbiddenHeaders: [String]? = nil,
                                         requiredHeaders: [String]? = nil,
                                         queryParams: [String]? = nil,
                                         forbiddenQueryParams: [String]? = nil,
                                         requiredQueryParams: [String]? = nil,
                                         body: ByteStream?,
                                         host: String,
                                         resolvedHost: String?) -> ExpectedSdkHttpRequest {
        let builder = ExpectedSdkHttpRequestBuilder()
        builder.withMethod(method)

        if let deconflictedHost = deconflictHost(host: host, resolvedHost: resolvedHost) {
            builder.withHost(deconflictedHost)
        }
        builder.withPath(path)

        if let queryParams = queryParams {
            addQueryItems(queryParams: queryParams, builder: builder)
        }

        if let forbiddenQueryParams = forbiddenQueryParams {
            addForbiddenQueryItems(queryParams: forbiddenQueryParams, builder: builder)
        }

        if let requiredQueryParams = requiredQueryParams {
            addRequiredQueryItems(queryParams: requiredQueryParams, builder: builder)
        }

        if let headers = headers {
            for (headerName, headerValue) in headers {
                let value = sanitizeStringForNonConformingValues(headerValue)
                builder.withHeader(name: headerName, value: value)
            }
        }

        if let forbiddenHeaders = forbiddenHeaders {
            for headerName in forbiddenHeaders {
                builder.withForbiddenHeader(name: headerName)
            }
        }

        if let requiredHeaders = requiredHeaders {
            for headerName in requiredHeaders {
                builder.withRequiredHeader(name: headerName)
            }
        }

        if let body = body {
            builder.withBody(body)
        }

        return builder.build()

    }

    func deconflictHost(host: String, resolvedHost: String?) -> String? {
        var deconflictedHost: String?
        if !host.isEmpty,
           let urlFromHost = ClientRuntime.URL(string: "http://\(host)"),
           let parsedHost = urlFromHost.host {
            deconflictedHost = parsedHost
        }
        if let resolvedHost = resolvedHost, !resolvedHost.isEmpty {
            deconflictedHost = resolvedHost
        }
        return deconflictedHost
    }

    public func urlPrefixFromHost(host: String) -> String? {
        guard !host.isEmpty, let hostCustomPath = URL(string: "http://\(host)")?.path else {
            return nil
        }
        return hostCustomPath
    }

    // Per spec, host can contain a path prefix, so this function is used to get only the host
    // https://smithy.io/2.0/additional-specs/http-protocol-compliance-tests.html#smithy-test-httprequesttests-trait
    public func hostOnlyFromHost(host: String) -> String? {
        guard !host.isEmpty, let hostOnly = URL(string: "http://\(host)")?.host else {
            return nil
        }
        return hostOnly
    }

    func addQueryItems(queryParams: [String], builder: ExpectedSdkHttpRequestBuilder) {
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            if queryParamComponents.count > 1 {
                let value = sanitizeStringForNonConformingValues(queryParamComponents[1])

                builder.withQueryItem(SDKURLQueryItem(name: queryParamComponents[0],
                                                   value: value))
            } else {
                builder.withQueryItem(SDKURLQueryItem(name: queryParamComponents[0], value: nil))
            }
        }
    }

    func addForbiddenQueryItems(queryParams: [String], builder: ExpectedSdkHttpRequestBuilder) {
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            if queryParamComponents.count > 1 {
                let value = sanitizeStringForNonConformingValues(queryParamComponents[1])

                builder.withForbiddenQueryItem(SDKURLQueryItem(name: queryParamComponents[0],
                                                   value: value))
            } else {
                builder.withForbiddenQueryItem(SDKURLQueryItem(name: queryParamComponents[0], value: nil))
            }
        }
    }

    func addRequiredQueryItems(queryParams: [String], builder: ExpectedSdkHttpRequestBuilder) {
        for queryParam in queryParams {
            let queryParamComponents = queryParam.components(separatedBy: "=")
            if queryParamComponents.count > 1 {
                let value = sanitizeStringForNonConformingValues(queryParamComponents[1])

                builder.withRequiredQueryItem(SDKURLQueryItem(name: queryParamComponents[0],
                                                   value: value))
            } else {
                builder.withRequiredQueryItem(SDKURLQueryItem(name: queryParamComponents[0], value: nil))
            }
        }
    }

    func sanitizeStringForNonConformingValues(_ input: String) -> String {
        switch input {
        case "Infinity": return "inf"
        case "-Infinity": return "-inf"
        case "NaN": return "nan"
        default:
            return input
        }
    }

    /**
     Check if a Query Item with given name exists in array of `URLQueryItem`
     */
    public func queryItemExists(_ queryItemName: String, in queryItems: [SDKURLQueryItem]?) -> Bool {
        guard let queryItems = queryItems else {
            return false
        }

        for queryItem in queryItems where queryItem.name == queryItemName {
            return true
        }
        return false
    }

    /**
    Check if a header with given name exists in array of `Header`
    */
    public func headerExists(_ headerName: String, in headers: [Header]) -> Bool {
        for header in headers where header.name == headerName {
            return true
        }
        return false
    }

    /**
     Asserts `HttpRequest` objects match
     /// - Parameter expected: Expected `HttpRequest`
     /// - Parameter actual: Actual `HttpRequest` to compare against
     /// - Parameter assertEqualHttpBody: Close to assert equality of `ByteStream` components
     */
    public func assertEqual(
        _ expected: ExpectedSdkHttpRequest,
        _ actual: SdkHttpRequest,
        _ assertEqualHttpBody: ((ByteStream?, ByteStream?) async throws -> Void)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        // assert headers match
        assertHttpHeaders(expected.headers, actual.headers, file: file, line: line)

        assertForbiddenHeaders(expected.forbiddenHeaders, actual.headers, file: file, line: line)

        assertRequiredHeaders(expected.requiredHeaders, actual.headers, file: file, line: line)

        assertQueryItems(expected.queryItems, actual.queryItems, file: file, line: line)

        XCTAssertEqual(expected.endpoint.uri.path, actual.destination.path, file: file, line: line)
        XCTAssertEqual(expected.endpoint.uri.host, actual.destination.host, file: file, line: line)
        XCTAssertEqual(expected.method, actual.method, file: file, line: line)
        assertForbiddenQueryItems(expected.forbiddenQueryItems, actual.queryItems, file: file, line: line)

        assertRequiredQueryItems(expected.requiredQueryItems, actual.queryItems, file: file, line: line)

        // assert the contents of ByteStream match, if no body was on the test, no assertions are to be made about the body
        // https://smithy.io/2.0/additional-specs/http-protocol-compliance-tests.html#smithy-test-httprequesttests-trait
        try await assertEqualHttpBody?(expected.body, actual.body)
    }

    public func genericAssertEqualHttpBodyData(
        expected: ByteStream,
        actual: ByteStream,
        contentType: HTTPBodyContentType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let expectedData = try await expected.readData()
        let actualData = try await actual.readData()
        compareData(contentType: contentType, expectedData, actualData, file: file, line: line)
    }

    private func extractData(_ httpBody: ByteStream) throws -> Result<Data?, Error> {
        switch httpBody {
        case .data(let actualData):
            return .success(actualData)
        case .stream(let byteStream):
            let data = try byteStream.readToEnd()
            return .success(data)
        case .noStream:
            return .failure(InternalHttpRequestTestBaseError("ByteStream is not Data Type"))
        }
    }

    private func compareData(contentType: HTTPBodyContentType, _ expected: Data?, _ actual: Data?, file: StaticString, line: UInt) {
        if let expected, let actual {
            let message = {
                let expectedStr = String(data: expected, encoding: .utf8) ?? "<not UTF-8>"
                let actualStr = String(data: actual, encoding: .utf8) ?? "<not UTF-8>"
                return "\nActual: \(actualStr)\nExpected: \(expectedStr)"
            }
            switch contentType {
            case .xml:
                XCTAssertXMLDataEqual(actual, expected, message(), file: file, line: line)
            case .json:
                XCTAssertJSONDataEqual(actual, expected, message(), file: file, line: line)
            case .formURL:
                XCTAssertFormURLDataEqual(actual, expected, message(), file: file, line: line)
            }
        } else if expected != nil && actual == nil {
            XCTFail("actual data in ByteStream is nil but expected is not", file: file, line: line)
        } else if expected == nil && actual != nil {
            XCTFail("expected data in ByteStream is nil but actual is not", file: file, line: line)
        } else {
            // expected and actual bodies are both nil, no operation
        }
    }

    /**
    Asserts `HttpHeaders` objects  match
    /// - Parameter expected: Expected `HttpHeaders`
    /// - Parameter actual: Actual `HttpHeaders` to compare against
    */
    public func assertHttpHeaders(
        _ expected: Headers?,
        _ actual: Headers?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected = expected else {
            return
        }

        guard let actual = actual else {
            XCTFail("There are expected headers and no actual headers.", file: file, line: line)
            return
        }

        expected.headers.forEach { header in
            XCTAssertTrue(actual.exists(name: header.name), file: file, line: line)

            guard actual.values(for: header.name) != header.value else {
                XCTAssertEqual(actual.values(for: header.name), header.value, file: file, line: line)
                return
            }

            let actualValue = actual.values(for: header.name)?.joined(separator: ", ")
            XCTAssertNotNil(actualValue, file: file, line: line)

            let expectedValue = header.value.joined(separator: ", ")
            XCTAssertEqual(actualValue, expectedValue, file: file, line: line)
        }
    }

    public func assertForbiddenHeaders(
        _ expected: [String]?,
        _ actual: Headers,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected = expected else {
            return
        }

        for forbiddenHeaderName in expected {
            XCTAssertFalse(actual.exists(name: forbiddenHeaderName),
                           """
                           forbidden header found: \(forbiddenHeaderName):
                           \(String(describing: actual.value(for: forbiddenHeaderName)))
                           """,
                           file: file,
                           line: line
            )
        }
    }

    public func assertRequiredHeaders(
        _ expected: [String]?,
        _ actual: Headers,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expected = expected else {
            return
        }

        for requiredHeaderName in expected {
            XCTAssertTrue(actual.exists(name: requiredHeaderName),
                          """
                          expected required header not found: \(requiredHeaderName):
                          \(String(describing: actual.value(for: requiredHeaderName)))
                          """,
                          file: file,
                          line: line
            )
        }
    }

    public func assertQueryItems(
        _ expected: [SDKURLQueryItem]?,
        _ actual: [SDKURLQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let expectedQueryItems = expected else {
            return
        }
        guard let actualQueryItems = actual else {
            XCTFail("actual query items in Endpoint is nil but expected are not", file: file, line: line)
            return
        }

        for expectedQueryItem in expectedQueryItems {
            let values = actualQueryItems.filter {$0.name == expectedQueryItem.name}.map { $0.value}
            XCTAssertNotNil(
                values,
                "expected query parameter \(expectedQueryItem.name); no values found",
                file: file,
                line: line
            )
            XCTAssertTrue(values.contains(expectedQueryItem.value),
                          """
                          expected query item value not found for \"\(expectedQueryItem.name)\".
                          Expected Value: \(expectedQueryItem.value ?? "nil")
                          Actual Values: \(values)
                          """,
                          file: file,
                          line: line
            )
        }
    }

    public func assertForbiddenQueryItems(
        _ expected: [SDKURLQueryItem]?,
        _ actual: [SDKURLQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let forbiddenQueryItems = expected else {
            return
        }
        guard let actualQueryItems = actual else {
            return
        }

        for forbiddenQueryItem in forbiddenQueryItems {
            XCTAssertFalse(actualQueryItems.contains(where: {$0.name == forbiddenQueryItem.name &&
                $0.value == forbiddenQueryItem.value}),
                           "forbidden query parameter item found:\(forbiddenQueryItem)",
            file: file,
            line: line
            )
        }
    }

    public func assertRequiredQueryItems(
        _ expected: [SDKURLQueryItem]?,
        _ actual: [SDKURLQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let requiredQueryItems = expected else {
            return
        }
        guard let actualQueryItems = actual else {
            XCTFail("actual query items in Endpoint is nil but required are not", file: file, line: line)
            return
        }

        for requiredQueryItem in requiredQueryItems {
            XCTAssertTrue(actualQueryItems.contains(where: {$0.name == requiredQueryItem.name &&
                $0.value == requiredQueryItem.value}),
                          "expected required query parameter not found:\(requiredQueryItem)",
                          file: file,
                          line: line
            )
        }
    }

    struct InternalHttpRequestTestBaseError: Error {
        let localizedDescription: String
        public init(_ description: String) {
            self.localizedDescription = description
        }
    }
}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}
