//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.XMLElement

public class DocumentWriter {

    public init() {}

    public func write<T>(_ value: T, rootElement: String, valueWriter: (T, Writer) throws -> Void) throws -> Data {
        let rootElement = XMLElement(name: rootElement)
        let writer = Writer(element: rootElement, nodeInfoPath: [], parent: nil)
        try valueWriter(value, writer)
        return Data(rootElement.xmlString.utf8)
    }
}
