//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI
import SmithyReadWrite
import SmithyXML
import SmithyReadWrite
import ClientRuntime
import XCTest

class NamespaceReaderTests: XCTestCase {

    func test_read() async throws {

        let xmlData = Data("""
        <SimpleScalarPropertiesInputOutput xmlns="https://example.com">
            <stringValue>string</stringValue>
            <trueBooleanValue>true</trueBooleanValue>
            <falseBooleanValue>false</falseBooleanValue>
            <byteValue>1</byteValue>
            <shortValue>2</shortValue>
            <integerValue>3</integerValue>
            <longValue>4</longValue>
            <floatValue>5.5</floatValue>
            <DoubleDribble>6.5</DoubleDribble>
            <Nested xmlns:xsi="https://example.com" xsi:someName="nestedAttrValue"></Nested>
        </SimpleScalarPropertiesInputOutput>

        """.utf8)
        let response = HttpResponse(body: .data(xmlData), statusCode: .ok)
        let subject = try await SimpleScalarPropertiesOutput.httpOutput(from:)(response)
        XCTAssertEqual(subject.nested?.attrField, "nestedAttrValue")
    }
}

// Copied from protocol tests

public struct SimpleScalarPropertiesOutput: Swift.Equatable {
    public var byteValue: Swift.Int8?
    public var doubleValue: Swift.Double?
    public var falseBooleanValue: Swift.Bool?
    public var floatValue: Swift.Float?
    public var foo: Swift.String?
    public var integerValue: Swift.Int?
    public var longValue: Swift.Int?
    public var nested: NestedWithNamespace?
    public var shortValue: Swift.Int16?
    public var stringValue: Swift.String?
    public var trueBooleanValue: Swift.Bool?

    public init(
        byteValue: Swift.Int8? = nil,
        doubleValue: Swift.Double? = nil,
        falseBooleanValue: Swift.Bool? = nil,
        floatValue: Swift.Float? = nil,
        foo: Swift.String? = nil,
        integerValue: Swift.Int? = nil,
        longValue: Swift.Int? = nil,
        nested: NestedWithNamespace? = nil,
        shortValue: Swift.Int16? = nil,
        stringValue: Swift.String? = nil,
        trueBooleanValue: Swift.Bool? = nil
    ) {
        self.byteValue = byteValue
        self.doubleValue = doubleValue
        self.falseBooleanValue = falseBooleanValue
        self.floatValue = floatValue
        self.foo = foo
        self.integerValue = integerValue
        self.longValue = longValue
        self.nested = nested
        self.shortValue = shortValue
        self.stringValue = stringValue
        self.trueBooleanValue = trueBooleanValue
    }
}

extension SimpleScalarPropertiesOutput {

    static func httpOutput(from httpResponse: HttpResponse) async throws -> SimpleScalarPropertiesOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyXML.Reader.from(data: data)
        let reader = responseReader
        var value = SimpleScalarPropertiesOutput()
        if let fooHeaderValue = httpResponse.headers.value(for: "X-Foo") {
            value.foo = fooHeaderValue
        }
        value.nested = try reader[.init("Nested", namespaceDef: .init(prefix: "xsi", uri: "https://example.com"))].readIfPresent(with: NestedWithNamespace.read(from:))
        value.byteValue = try reader["byteValue"].readIfPresent()
        value.doubleValue = try reader["DoubleDribble"].readIfPresent()
        value.falseBooleanValue = try reader["falseBooleanValue"].readIfPresent()
        value.floatValue = try reader["floatValue"].readIfPresent()
        value.integerValue = try reader["integerValue"].readIfPresent()
        value.longValue = try reader["longValue"].readIfPresent()
        value.shortValue = try reader["shortValue"].readIfPresent()
        value.stringValue = try reader["stringValue"].readIfPresent()
        value.trueBooleanValue = try reader["trueBooleanValue"].readIfPresent()
        return value
    }
}

public struct NestedWithNamespace: Swift.Equatable {
    public var attrField: Swift.String?

    public init(attrField: Swift.String? = nil) {
        self.attrField = attrField
    }
}

extension NestedWithNamespace {

    static func write(value: NestedWithNamespace?, to writer: SmithyXML.Writer) throws {
        guard let value else { return }
        try writer[.init("xsi:someName", location: .attribute)].write(value.attrField)
    }

    static func read(from reader: Reader) throws -> NestedWithNamespace {
        guard reader.hasContent else { throw ReaderError.requiredValueNotPresent }
        var value = NestedWithNamespace()
        value.attrField = try reader[.init("xsi:someName", location: .attribute)].readIfPresent()
        return value
    }
}
