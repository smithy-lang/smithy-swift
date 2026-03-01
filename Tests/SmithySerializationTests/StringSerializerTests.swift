//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SmithySerialization
import enum Smithy.Prelude
import struct Smithy.Schema
import struct Smithy.SensitiveTrait

final class StringSerializerTests: XCTestCase {

    func test_writesASimpleString() throws {
        let string = "xyz"
        let schema = Smithy.Prelude.stringSchema

        let subject = StringSerializer()
        try subject.writeString(schema, string)

        XCTAssertEqual(subject.string, "\"\(string)\"")
    }

    func test_writesASimpleInt() throws {
        let int = 8675309
        let schema = Smithy.Prelude.integerSchema

        let subject = StringSerializer()
        try subject.writeInteger(schema, int)

        XCTAssertEqual(subject.string, "\(int)")
    }

    func test_writesATimestamp() throws {
        let dateString = "2026-01-21T20:23:32Z"
        let df = ISO8601DateFormatter()
        let date = try XCTUnwrap(df.date(from: dateString))
        let schema = Smithy.Prelude.timestampSchema

        let subject = StringSerializer()
        try subject.writeTimestamp(schema, date)

        XCTAssertEqual(subject.string, dateString)
    }

    func test_writesAnEmptyList() throws {
        let subject = TestStruct(publicList: [])

        XCTAssertEqual(subject.debugDescription, "TestStruct(publicList: [])")
    }

    func test_writesAStringList() throws {
        let subject = TestStruct(publicList: ["abc", "def", "ghi"])

        XCTAssertEqual(subject.debugDescription, "TestStruct(publicList: [\"abc\", \"def\", \"ghi\"])")
    }

    func test_writesAnEmptyMap() throws {
        let subject = TestStruct(publicMap: [:])

        XCTAssertEqual(subject.debugDescription, "TestStruct(publicMap: [:])")
    }

    func test_writesAStringMap() throws {
        let subject = TestStruct(publicMap: ["x": "abc", "y": "def"])

        XCTAssert(
            subject.debugDescription == "TestStruct(publicMap: [\"x\": \"abc\", \"y\": \"def\"])" ||
            subject.debugDescription == "TestStruct(publicMap: [\"y\": \"def\", \"x\": \"abc\"])"
        )
    }

    func test_redactsStringProperty() throws {
        let subject = TestStruct(publicString: "abc", privateString: "def")

        XCTAssertEqual(subject.debugDescription, "TestStruct(publicString: \"abc\", privateString: [REDACTED])")
    }

    func test_redactsAPrivateList() throws {
        let subject = TestStruct(privateList: ["abc", "def", "ghi"])

        XCTAssertEqual(subject.debugDescription, "TestStruct(privateList: [[REDACTED], [REDACTED], [REDACTED]])")
    }

    func test_redactsAPrivateMap() throws {
        let subject = TestStruct(privateMap: ["x": "abc", "y": "def"])

        XCTAssert(
            subject.debugDescription == "TestStruct(privateMap: [\"x\": [REDACTED], \"y\": [REDACTED]])" ||
            subject.debugDescription == "TestStruct(privateMap: [\"y\": [REDACTED], \"x\": [REDACTED]])",
            "actual: \(subject.debugDescription)"
        )
    }
}

private struct TestStruct {
    let publicString: String?
    let publicList: [String]?
    let publicMap: [String: String]?
    let privateString: String?
    let privateList: [String]?
    let privateMap: [String: String]?

    init(
        publicString: String? = nil,
        publicList: [String]? = nil,
        publicMap: [String: String]? = nil,
        privateString: String? = nil,
        privateList: [String]? = nil,
        privateMap: [String: String]? = nil
    ) {
        self.publicString = publicString
        self.publicList = publicList
        self.publicMap = publicMap
        self.privateString = privateString
        self.privateList = privateList
        self.privateMap = privateMap
    }
}

extension TestStruct: SerializableStruct {

    static var writeConsumer: SmithySerialization.WriteStructConsumer<TestStruct> {
        { member, value, serializer in
            switch member.index {
            case 0:
                guard let value = value.publicString else { break }
                try serializer.writeString(member, value)
            case 1:
                guard let value = value.publicList else { break }
                try serializer.writeList(member, value) { value, serializer in
                    try serializer.writeString(member.target!.member, value)
                }
            case 2:
                guard let value = value.publicMap else { break }
                try serializer.writeMap(member, value) { value, serializer in
                    try serializer.writeString(member.target!.value, value)
                }
            case 3:
                guard let value = value.privateString else { break }
                try serializer.writeString(member, value)
            case 4:
                guard let value = value.privateList else { break }
                try serializer.writeList(member, value) { value, serializer in
                    try serializer.writeString(member.target!.member, value)
                }
            case 5:
                guard let value = value.privateMap else { break }
                try serializer.writeMap(member, value) { value, serializer in
                    try serializer.writeString(member.target!.value, value)
                }
            default: break
            }
        }
    }
    
    func serialize(_ serializer: any SmithySerialization.ShapeSerializer) throws {
        try serializer.writeStruct(Self.schema, self)
    }
    
    private static var schema = Schema(
        id: .init("swift.test", "TestStruct"),
        type: .structure,
        members: [
            .init(
                id: .init("swift.test", "TestStruct", "publicString"),
                type: .member,
                containerType: .structure,
                target: Smithy.Prelude.stringSchema,
                index: 0
            ),
            .init(
                id: .init("swift.test", "TestStruct", "publicList"),
                type: .member,
                containerType: .structure,
                target: publicListSchema,
                index: 1
            ),
            .init(
                id: .init("swift.test", "TestStruct", "publicMap"),
                type: .member,
                containerType: .structure,
                target: publicMapSchema,
                index: 2
            ),
            .init(
                id: .init("swift.test", "TestStruct", "privateString"),
                type: .member,
                traits: [SensitiveTrait()],
                containerType: .structure,
                target: privateStringSchema,
                index: 3
            ),
            .init(
                id: .init("swift.test", "TestStruct", "privateList"),
                type: .member,
                containerType: .structure,
                target: privateListSchema,
                index: 4
            ),
            .init(
                id: .init("swift.test", "TestStruct", "privateMap"),
                type: .member,
                containerType: .structure,
                target: privateMapSchema,
                index: 5
            ),
        ]
    )

    private static var publicListSchema = Schema(
        id: .init("swift.test", "PublicList"),
        type: .list,
        members: [
            .init(
                id: .init("swift.test", "PublicList", "member"),
                type: .member,
                target: Smithy.Prelude.stringSchema,
                index: 0
            )
        ]
    )

    private static var publicMapSchema = Schema(
        id: .init("swift.test", "PublicMap"),
        type: .map,
        members: [
            .init(
                id: .init("swift.test", "PublicMap", "key"),
                type: .member,
                containerType: .map,
                target: Smithy.Prelude.stringSchema,
                index: 0
            ),
            .init(
                id: .init("swift.test", "PublicMap", "value"),
                type: .member,
                containerType: .map,
                target: Smithy.Prelude.stringSchema,
                index: 1
            )
        ]
    )

    private static var privateStringSchema = Schema(
        id: .init("swift.test", "PrivateString"),
        type: .string,
        traits: [SensitiveTrait()]
    )

    private static var privateListSchema = Schema(
        id: .init("swift.test", "PrivateList"),
        type: .list,
        members: [
            .init(
                id: .init("swift.test", "PrivateList", "member"),
                type: .member,
                traits: [SensitiveTrait()],
                containerType: .list,
                target: privateStringSchema,
                index: 0
            )
        ]
    )

    private static var privateMapSchema = Schema(
        id: .init("swift.test", "PrivateMap"),
        type: .map,
        members: [
            .init(
                id: .init("swift.test", "PrivateMap", "key"),
                type: .member,
                containerType: .map,
                target: Smithy.Prelude.stringSchema,
                index: 0
            ),
            .init(
                id: .init("swift.test", "PrivateMap", "value"),
                type: .member,
                traits: [SensitiveTrait()],
                containerType: .map,
                target: privateStringSchema,
                index: 1
            )
        ]
    )

}
