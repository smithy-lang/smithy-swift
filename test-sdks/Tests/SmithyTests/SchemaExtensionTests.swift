//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
@testable
import Smithy
import XCTest

final class SchemaExtensionTests: XCTestCase {

    // A schema extension that records the schema it was created from, so tests can verify
    // that creation happened & that the correct schema was passed to the initializer.
    final class TestExtension: SchemaExtension {
        static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

        let memberName: String?

        init(schema: Schema) throws {
            self.memberName = schema.id.member
        }
    }

    // A second extension type, to verify that extensions of different types don't collide.
    final class OtherTestExtension: SchemaExtension {
        static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

        init(schema: Schema) throws {}
    }

    // A schema extension that always fails to initialize, to verify errors are propagated.
    final class ThrowingTestExtension: SchemaExtension {
        static let uniqueIndex = schemaExtensionUniqueIndexCounter.getNextIndex()

        struct Failure: Error {}

        init(schema: Schema) throws {
            throw Failure()
        }
    }

    private func makeSchema(member: String = "someMember") -> Schema {
        Schema(
            id: .init("ns.test", "TestStruct", member),
            type: .string,
            containerType: .structure,
            index: 0
        )
    }

    // MARK: - getExtension / setExtension

    func test_getExtension_returnsNilWhenNoExtensionIsStored() {
        let schema = makeSchema()

        XCTAssertNil(schema.getExtension(TestExtension.self))
    }

    func test_setExtension_storesAnExtensionThatIsThenRetrievable() throws {
        let schema = makeSchema()
        let ext = try TestExtension(schema: schema)

        schema.setExtension(ext)

        XCTAssertTrue(schema.getExtension(TestExtension.self) === ext)
    }

    func test_setExtension_replacesAPreviouslyStoredExtensionOfTheSameType() throws {
        let schema = makeSchema()
        let first = try TestExtension(schema: schema)
        let second = try TestExtension(schema: schema)

        schema.setExtension(first)
        schema.setExtension(second)

        XCTAssertTrue(schema.getExtension(TestExtension.self) === second)
    }

    func test_getExtension_doesNotConfuseExtensionsOfDifferentTypes() throws {
        let schema = makeSchema()
        let ext = try TestExtension(schema: schema)

        schema.setExtension(ext)

        XCTAssertTrue(schema.getExtension(TestExtension.self) === ext)
        XCTAssertNil(schema.getExtension(OtherTestExtension.self))
    }

    func test_extensions_areStoredPerSchemaInstance() throws {
        let schema = makeSchema(member: "memberA")
        let otherSchema = makeSchema(member: "memberB")

        schema.setExtension(try TestExtension(schema: schema))

        XCTAssertNotNil(schema.getExtension(TestExtension.self))
        XCTAssertNil(otherSchema.getExtension(TestExtension.self))
    }

    // MARK: - getOrCreateExtension

    func test_getOrCreateExtension_createsTheExtensionWhenNoneIsStored() throws {
        let schema = makeSchema(member: "createdMember")

        let ext = try schema.getOrCreateExtension(TestExtension.self)

        XCTAssertEqual(ext.memberName, "createdMember")
    }

    func test_getOrCreateExtension_storesTheExtensionItCreates() throws {
        let schema = makeSchema()

        let ext = try schema.getOrCreateExtension(TestExtension.self)

        XCTAssertTrue(schema.getExtension(TestExtension.self) === ext)
    }

    func test_getOrCreateExtension_returnsTheSameInstanceOnSubsequentCalls() throws {
        let schema = makeSchema()

        let first = try schema.getOrCreateExtension(TestExtension.self)
        let second = try schema.getOrCreateExtension(TestExtension.self)

        XCTAssertTrue(first === second)
    }

    func test_getOrCreateExtension_returnsAPreviouslyStoredExtensionWithoutCreatingANewOne() throws {
        let schema = makeSchema()
        let stored = try TestExtension(schema: schema)
        schema.setExtension(stored)

        let retrieved = try schema.getOrCreateExtension(TestExtension.self)

        XCTAssertTrue(retrieved === stored)
    }

    func test_getOrCreateExtension_propagatesAnErrorThrownByTheExtensionInitializer() {
        let schema = makeSchema()

        XCTAssertThrowsError(try schema.getOrCreateExtension(ThrowingTestExtension.self)) { error in
            XCTAssertTrue(error is ThrowingTestExtension.Failure)
        }
        XCTAssertNil(schema.getExtension(ThrowingTestExtension.self))
    }

    // MARK: - Concurrency

    func test_getOrCreateExtension_isThreadSafeAndAlwaysReturnsAUsableExtension() throws {
        // Creation & storage is intentionally not atomic, so multiple threads may each create
        // an extension.  Whichever instance is returned must always be fully formed & correct,
        // and exactly one must remain stored at the end.
        let schema = makeSchema(member: "concurrentMember")

        DispatchQueue.concurrentPerform(iterations: 500) { _ in
            let ext = try? schema.getOrCreateExtension(TestExtension.self)
            XCTAssertEqual(ext?.memberName, "concurrentMember")
        }

        XCTAssertEqual(schema.getExtension(TestExtension.self)?.memberName, "concurrentMember")
    }
}
