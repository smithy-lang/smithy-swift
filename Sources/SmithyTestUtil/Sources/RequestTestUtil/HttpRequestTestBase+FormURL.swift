//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest
import ClientRuntime

extension HttpRequestTestBase {
    public func assertEqualFormURLBody(_ expected: Data, _ actual: Data) {
        let expectedQueryItems = convertToQueryItems(data: expected)
        let acutalQueryItems = convertToQueryItems(data: actual)
        assertEqualQueryItems(expectedQueryItems, acutalQueryItems)
    }

    private func convertToQueryItems(data: Data) -> [URLQueryItem] {
        guard let queryString = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to decode data")
            return []
        }
        var queryItems: [URLQueryItem] = []
        let keyValuePairs = queryString.components(separatedBy: "\n")
        for keyValue in keyValuePairs {
            let keyValueArray = keyValue.components(separatedBy: "=")
            guard keyValueArray.count >= 1 else {
                XCTFail("Failed to decode query string. Problem with the encoding? Query string is:\n\(queryString)")
                return []
            }
            let name: String = sanitizeQueryStringName(keyValueArray[0])
            let value = keyValueArray.count >= 2 ? keyValueArray[1] : nil
            queryItems.append(URLQueryItem(name: name, value: value))
        }
        return queryItems
    }

    private func sanitizeQueryStringName(_ name: String) -> String {
        return name.hasPrefix("&") ? String(name.dropFirst()) : name
    }
}
