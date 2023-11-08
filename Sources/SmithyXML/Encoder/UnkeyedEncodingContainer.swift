//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class UnkeyedEncodingContainer: Swift.UnkeyedEncodingContainer {
    let element: XMLElement
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    var count: Int { element.childCount }

    init(element: XMLElement, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.element = element
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    func encode<T: Encodable>(_ value: T) throws {
        //
    }

    func encodeNil() throws {
        //
    }
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> Swift.KeyedEncodingContainer<NestedKey> {
        let newKey = UnkeyedCodingKey(intValue: element.childCount)
        let newChild = XMLElement(name: newKey.stringValue)
        return Swift.KeyedEncodingContainer(KeyedEncodingContainer(element: newChild, codingPath: codingPath + [newKey], userInfo: userInfo))
    }
    
    func nestedUnkeyedContainer() -> Swift.UnkeyedEncodingContainer {
        let newKey = UnkeyedCodingKey(intValue: element.childCount)
        let newChild = XMLElement(name: newKey.stringValue)
        return UnkeyedEncodingContainer(element: newChild, codingPath: codingPath + [newKey], userInfo: userInfo)
    }
    
    func superEncoder() -> Swift.Encoder {
        fatalError("Encoding not supported for reference types")
    }
}

struct UnkeyedCodingKey: CodingKey {
    var stringValue: String { intValue.map { "\($0)" } ?? "" }
    let intValue: Int?

    init(intValue: Int) {
        self.intValue = intValue
    }

    init?(stringValue: String) {
        guard let intValue = Int(stringValue) else { return nil }
        self.intValue = intValue
    }
}
