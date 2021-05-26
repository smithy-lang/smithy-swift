//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct FormURLEncoding: Encoder {

    final class EncodedData {
        private(set) var strings: [String: String] = [:]
        
        func encode(key codingKey: [CodingKey], value: String) {
            let key = codingKey.map {
                $0.stringValue
            }.filter {
                !$0.isEmpty
            }.joined(separator: ".")

            strings[key] = value
        }
    }
    
    var data: EncodedData

    init(to encodedData: EncodedData = EncodedData()) {
        self.data = encodedData
    }

    // MARK: Encoder conformance
    var codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any] = [:]

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        var container = FormURLKeyedEncoding<Key>(to: data)
        container.codingPath = codingPath
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        var container = FormURLUnkeyedEncoding(to: data)
        container.codingPath = codingPath
        return container
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        var container = FormURLSingleValueEncoding(to: data)
        container.codingPath = codingPath
        return container
    }
}
