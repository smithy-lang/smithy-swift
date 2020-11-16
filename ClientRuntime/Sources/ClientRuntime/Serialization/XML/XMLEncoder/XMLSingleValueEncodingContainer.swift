//
//  XMLSingleValueEncodingContainer.swift
//  ClientRuntime
//
// TODO:: Add copyrights

import Foundation

extension XMLEncoderImplementation: SingleValueEncodingContainer {
    // MARK: - SingleValueEncodingContainer Methods

    func assertCanEncodeNewValue() {
        precondition(
            canEncodeNewValue,
            """
            Attempt to encode value through single value container when \
            previously value already encoded.
            """
        )
    }

    public func encodeNil() throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer())
    }

    public func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        try storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode<T: Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        storage.push(container: addToXMLContainer(value))
    }

    public func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        try storage.push(container: addToXMLContainer(value))
    }
}
