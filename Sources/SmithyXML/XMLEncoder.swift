//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(SmithyXML)
public class XMLEncoder {

    public init() {}

    public func encode<T: Encodable>(_ value: T, rootElement: String) throws -> Data {
        let rootElement = XMLElement(name: rootElement)
        let document = XMLDocument(rootElement: rootElement)
        document.characterEncoding = "UTF-8"
        let encoder = Encoder(element: rootElement, codingPath: [], userInfo: [:])
        try value.encode(to: encoder)
        return document.xmlData
    }
}
