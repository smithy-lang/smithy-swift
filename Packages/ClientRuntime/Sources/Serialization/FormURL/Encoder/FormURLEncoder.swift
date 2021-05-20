//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
//Heavily inspired from:
//https://stackoverflow.com/questions/45169254/custom-swift-encoder-decoder-for-the-strings-resource-format

public class FormURLEncoder: RequestEncoder {
    public init() {
    }
    public func encode<T>(_ value: T) throws -> Data where T:Encodable {
        let stringsEncoding = FormURLEncoding()
        try value.encode(to: stringsEncoding)
        let formEncoded = formURLEncodeFormat(from: stringsEncoding.data.strings)
        return formEncoded.data(using: .utf8) ?? Data()
    }
    
    private func formURLEncodeFormat(from strings: [String:String]) -> String {
        // TODO: Add percent encode
        let dotStrings = strings.map { key,value in
            "\(key)=\(value)"
        }
        return dotStrings.joined(separator: "\n&")

    }
}
