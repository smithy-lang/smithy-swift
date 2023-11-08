//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class Encoder: Swift.Encoder {
    let element: XMLElement
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    init(element: XMLElement, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.element = element
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> Swift.KeyedEncodingContainer<Key> {
        let keyedEncodingContainer = KeyedEncodingContainer<Key>(element: element, codingPath: codingPath, userInfo: userInfo)
        return Swift.KeyedEncodingContainer(keyedEncodingContainer)
    }
    
    func unkeyedContainer() -> Swift.UnkeyedEncodingContainer {
        return UnkeyedEncodingContainer(element: element, codingPath: codingPath, userInfo: userInfo)
    }
    
    func singleValueContainer() -> Swift.SingleValueEncodingContainer {
        return SingleValueEncodingContainer(element: element, codingPath: codingPath, userInfo: userInfo)
    }
}
