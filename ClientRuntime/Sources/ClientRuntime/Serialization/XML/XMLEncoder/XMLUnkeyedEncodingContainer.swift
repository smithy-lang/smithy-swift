/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLUnkeyedEncodingContainer.swift
//  ClientRuntime


import Foundation

struct XMLUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    // MARK: Properties

    /// A reference to the encoder we're writing to.
    private let encoder: XMLEncoderImplementation

    /// A reference to the container we're writing to.
    private let container: XMLSharedContainer<XMLArrayBasedContainer>

    /// The path of coding keys taken to get to this point in encoding.
    public private(set) var codingPath: [CodingKey]

    /// The number of elements encoded into the container.
    public var count: Int {
        return container.withShared { $0.count }
    }

    // MARK: - Initialization

    /// Initializes `self` with the given references.
    init(
        referencing encoder: XMLEncoderImplementation,
        codingPath: [CodingKey],
        wrapping container: XMLSharedContainer<XMLArrayBasedContainer>
    ) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    // MARK: - UnkeyedEncodingContainer Methods

    public mutating func encodeNil() throws {
        container.withShared { container in
            container.append(encoder.addToXMLContainer())
        }
    }

    public mutating func encode<T: Encodable>(_ value: T) throws {
        try encode(value) { encoder, value in
            try encoder.addToXMLContainer(value)
        }
    }

    private mutating func encode<T: Encodable>(
        _ value: T,
        encode: (XMLEncoderImplementation, T) throws -> XMLContainer
    ) rethrows {
        encoder.codingPath.append(XMLKey(index: count))
        defer { self.encoder.codingPath.removeLast() }

        try container.withShared { container in
            container.append(try encode(encoder, value))
        }
    }

    public mutating func nestedContainer<NestedKey>(
        keyedBy _: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> {
        return nestedKeyedContainer(keyedBy: NestedKey.self)
    }

    public mutating func nestedKeyedContainer<NestedKey>(keyedBy _: NestedKey.Type)
    -> KeyedEncodingContainer<NestedKey> {
        codingPath.append(XMLKey(index: count))
        defer { self.codingPath.removeLast() }

        let sharedKeyed = XMLSharedContainer(XMLKeyBasedContainer())
        self.container.withShared { container in
            container.append(sharedKeyed)
        }

        let container = XMLKeyedEncodingContainer<NestedKey>(
            referencing: encoder,
            codingPath: codingPath,
            wrapping: sharedKeyed
        )
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        codingPath.append(XMLKey(index: count))
        defer { self.codingPath.removeLast() }

        let sharedUnkeyed = XMLSharedContainer(XMLArrayBasedContainer())
        container.withShared { container in
            container.append(sharedUnkeyed)
        }

        return XMLUnkeyedEncodingContainer(
            referencing: encoder,
            codingPath: codingPath,
            wrapping: sharedUnkeyed
        )
    }

    public mutating func superEncoder() -> Encoder {
        return XMLReferencingEncoder(
            referencing: encoder,
            at: count,
            wrapping: container
        )
    }
}
