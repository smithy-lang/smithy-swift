//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import ClientRuntime
import Smithy
import SmithyHTTPAPI
import XCTest

/**
 Includes Utility functions for Http Protocol Request Serialization Tests
 */
public typealias ValidateCallback = (Data, Data) -> Void

public enum HTTPBodyContentType {
    case xml
    case json
    case formURL
    case cbor
}

extension HTTPBodyContentType {

    /// Determines the body format from a media type, e.g. `application/json`.
    ///
    /// Returns `nil` for media types that are compared byte-for-byte, or if the media type is `nil`.
    public init?(mediaType: String?) {
        // Match anywhere in the media type, so that e.g. `application/x-amz-json-1.0` is JSON.
        let mediaType = mediaType?.lowercased() ?? ""
        if mediaType.contains("x-www-form-urlencoded") {
            self = .formURL
        } else if mediaType.contains("json") {
            self = .json
        } else if mediaType.contains("cbor") {
            self = .cbor
        } else if mediaType.contains("xml") {
            self = .xml
        } else {
            return nil
        }
    }
}

open class HttpRequestTestBase: XCTestCase {

    open override func setUp() {
        CommonRuntimeKit.initialize()
    }

    /**
     Create `HttpRequest` from its components
     */
    public func buildExpectedHttpRequest(method: HTTPMethodType,
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

    func deconflictHost(host: String, resolvedHost: String?) -> String? {
        HTTPRequestTestSupport.deconflictHost(host: host, resolvedHost: resolvedHost)
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

    /**
     Check if a Query Item with given name exists in array of `URLQueryItem`
     */
    public func queryItemExists(_ queryItemName: String, in queryItems: [URIQueryItem]?) -> Bool {
        queryItems?.contains { $0.name == queryItemName } ?? false
    }

    /**
    Check if a header with given name exists in array of `Header`
    */
    public func headerExists(_ headerName: String, in headers: [Header]) -> Bool {
        headers.contains { $0.name == headerName }
    }

    /**
     Asserts `HttpRequest` objects match
     /// - Parameter expected: Expected `HttpRequest`
     /// - Parameter actual: Actual `HttpRequest` to compare against
     /// - Parameter assertEqualHttpBody: Close to assert equality of `ByteStream` components
     */
    public func assertEqual(
        _ expected: ExpectedSdkHttpRequest,
        _ actual: SmithyHTTPAPI.HTTPRequest,
        _ assertEqualHttpBody: ((ByteStream?, ByteStream?) async throws -> Void)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        try await HTTPRequestTestSupport.assertEqual(
            expected, actual, assertEqualHttpBody, reporter: .xcTest(file: file, line: line)
        )
    }

    public func genericAssertEqualHttpBodyData(
        expected: ByteStream,
        actual: ByteStream,
        contentType: HTTPBodyContentType,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        try await HTTPRequestTestSupport.genericAssertEqualHttpBodyData(
            expected: expected, actual: actual, contentType: contentType, reporter: .xcTest(file: file, line: line)
        )
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
        HTTPRequestTestSupport.assertHttpHeaders(expected, actual, reporter: .xcTest(file: file, line: line))
    }

    public func assertForbiddenHeaders(
        _ expected: [String]?,
        _ actual: Headers,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        HTTPRequestTestSupport.assertForbiddenHeaders(expected, actual, reporter: .xcTest(file: file, line: line))
    }

    public func assertRequiredHeaders(
        _ expected: [String]?,
        _ actual: Headers,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        HTTPRequestTestSupport.assertRequiredHeaders(expected, actual, reporter: .xcTest(file: file, line: line))
    }

    public func assertQueryItems(
        _ expected: [URIQueryItem]?,
        _ actual: [URIQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        HTTPRequestTestSupport.assertQueryItems(expected, actual, reporter: .xcTest(file: file, line: line))
    }

    public func assertForbiddenQueryItems(
        _ expected: [URIQueryItem]?,
        _ actual: [URIQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        HTTPRequestTestSupport.assertForbiddenQueryItems(expected, actual, reporter: .xcTest(file: file, line: line))
    }

    public func assertRequiredQueryItems(
        _ expected: [URIQueryItem]?,
        _ actual: [URIQueryItem]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        HTTPRequestTestSupport.assertRequiredQueryItems(expected, actual, reporter: .xcTest(file: file, line: line))
    }
}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}
