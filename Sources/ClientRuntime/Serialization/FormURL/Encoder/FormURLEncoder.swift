//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Inspired from:
// https://stackoverflow.com/questions/45169254/custom-swift-encoder-decoder-for-the-strings-resource-format

public class FormURLEncoder: RequestEncoder {
    public var messageEncoder: MessageEncoder? = nil
    
    public init() {}

    public func encode<T>(_ value: T) throws -> Data where T: Encodable {
        let formURLEncoding = FormURLEncoding()
        try value.encode(to: formURLEncoding)
        let sortedKeyValues = formURLEncoding.data.strings.sorted(by: { keyVal1, keyVal2 in
            keyVal1.key < keyVal2.key
        })
        let formEncodedString = formURLEncodeFormat(from: sortedKeyValues)
        return formEncodedString.data(using: .utf8) ?? Data()
    }

    private func formURLEncodeFormat(from strings: [(String, String)]) -> String {
        let keyValues = strings.map { key, value in
            "\(key.urlPercentEncoding())=\(value.urlPercentEncoding())"
        }
        return keyValues.joined(separator: "&")
    }
}
