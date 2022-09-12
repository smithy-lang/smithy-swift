//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest
import SmithyClientRuntime

extension HttpRequestTestBase {
    public func assertEqualFormURLBody(_ expected: Data, _ actual: Data) {
        let expectedQueryItems = convertToQueryItems(data: expected)
        let actualQueryItems = convertToQueryItems(data: actual)
        assertQueryItems(expectedQueryItems, actualQueryItems)
    }

    private func convertToQueryItems(data: Data) -> [URLQueryItem] {
        guard let queryString = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to decode data")
            return []
        }
        var queryItems: [URLQueryItem] = []
        let sanitizedQueryString = queryString.replacingOccurrences(of: "\n", with: "")
        let keyValuePairs = sanitizedQueryString.components(separatedBy: "&")
        for keyValue in keyValuePairs {
            let keyValueArray = keyValue.components(separatedBy: "=")
            guard keyValueArray.count >= 1 else {
                XCTFail("Failed to decode query string. Problem with the encoding? Query string is:\n\(queryString)")
                return []
            }
            let name: String = keyValueArray[0]
            let value = keyValueArray.count >= 2 ? sanitizeStringForNonConformingValues(keyValueArray[1]) : nil
            queryItems.append(URLQueryItem(name: name, value: value))
        }
        return queryItems
    }
}
