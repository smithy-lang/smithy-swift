//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

//class KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
//    let element: XMLElement
//    let codingPath: [CodingKey]
//    let userInfo: [CodingUserInfoKey: Any]
//
//    init(element: XMLElement, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
//        self.element = element
//        self.codingPath = codingPath
//        self.userInfo = userInfo
//        update(element: element, key: codingPath.last as? XMLCodingKey)
//    }
//
//    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> Swift.KeyedEncodingContainer<NestedKey> {
//        let kind = (key as? XMLCodingKey)?.kind ?? .element
//        let newChild = XMLElement(kind: kind)
//        newChild.name = key.stringValue
//        element.addChild(newChild)
//        return Swift.KeyedEncodingContainer(KeyedEncodingContainer<NestedKey>(element: newChild, codingPath: codingPath + [key], userInfo: userInfo))
//    }
//    
//    func nestedUnkeyedContainer(forKey key: Key) -> Swift.UnkeyedEncodingContainer {
//        let kind = (key as? XMLCodingKey)?.kind ?? .element
//        let newChild = XMLElement(kind: kind)
//        newChild.name = key.stringValue
//        element.addChild(newChild)
//        return UnkeyedEncodingContainer(element: newChild, codingPath: codingPath + [key], userInfo: userInfo)
//    }
//    
//    func superEncoder() -> Swift.Encoder {
//        fatalError("Encoding of reference types not supported")
//    }
//    
//    func superEncoder(forKey key: Key) -> Swift.Encoder {
//        fatalError("Encoding of reference types not supported")
//    }
//
//    func encodeNil(forKey key: Key) throws {
//        let kind = (key as? XMLCodingKey)?.kind ?? .element
//        let newChild = XMLElement(kind: kind)
//        newChild.name = key.stringValue
//        element.stringValue = "null"
//        element.addChild(newChild)
//    }
//
//    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
//        let newChild = XMLElement(name: key.stringValue)
//        element.addChild(newChild)
//        let encoder = Encoder(element: newChild, codingPath: codingPath + [key], userInfo: userInfo)
//        try value.encode(to: encoder)
//    }
//}
//
