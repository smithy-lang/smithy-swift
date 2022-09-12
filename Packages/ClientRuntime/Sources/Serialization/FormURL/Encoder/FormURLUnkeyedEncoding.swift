//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct FormURLUnkeyedEncoding: UnkeyedEncodingContainer {
    
    private let data: FormURLEncoding.EncodedData
    
    init(to data: FormURLEncoding.EncodedData) {
        self.data = data
    }
    
    var codingPath: [CodingKey] = []
    
    private(set) var count: Int = 1
    
    mutating func encodeNil() throws {
        data.encode(key: codingPath, value: "nil")
    }
    
    mutating func encode(_ value: Bool) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: String) throws {
        data.encode(key: codingPath, value: value)
    }
    
    mutating func encode(_ value: Double) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: Float) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: Int) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: Int8) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: Int16) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: Int32) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: Int64) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: UInt) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: UInt8) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: UInt16) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: UInt32) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode(_ value: UInt64) throws {
        data.encode(key: codingPath, value: value.description)
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        var stringsEncoding = FormURLEncoding(to: data)
        stringsEncoding.codingPath = codingPath
        try value.encode(to: stringsEncoding)
    }
    
    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        var container = FormURLKeyedEncoding<NestedKey>(to: data)
        container.codingPath = codingPath
        return KeyedEncodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        var container = FormURLUnkeyedEncoding(to: data)
        container.codingPath = codingPath
        return container
    }
    
    mutating func superEncoder() -> Encoder {
        let stringsEncoding = FormURLEncoding(to: data)
        return stringsEncoding
    }
}
