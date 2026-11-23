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

final class SchemaTests: XCTestCase {

    private let inputSchema = Schema(id: .init("ns.test", "TestInput"), type: .structure)
    private let outputSchema = Schema(id: .init("ns.test", "TestOutput"), type: .structure)

    private func makeMember(_ name: String, index: Int, target: Schema?) -> Schema {
        Schema(
            id: .init("ns.test", "TestOperation", name),
            type: .structure,
            containerType: .operation,
            target: target,
            index: index
        )
    }

    private func makeOperation(members: [Schema]) -> Schema {
        Schema(id: .init("ns.test", "TestOperation"), type: .operation, members: members)
    }

    private func makeCompleteOperation() -> Schema {
        makeOperation(members: [
            makeMember("input", index: 0, target: inputSchema),
            makeMember("output", index: 1, target: outputSchema),
        ])
    }

    // A structure with two members, so that member presence is not what causes the throw.
    private func makeStructure() -> Schema {
        Schema(id: .init("ns.test", "TestStruct"), type: .structure, members: [
            makeMember("input", index: 0, target: inputSchema),
            makeMember("output", index: 1, target: outputSchema),
        ])
    }

    private func assertThrowsSchemaError(
        _ expression: @autoclosure () throws -> Schema,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            XCTAssertTrue(error is SchemaError, "Expected SchemaError, got \(error)", file: file, line: line)
        }
    }

    // MARK: - input

    func test_input_returnsTheTargetOfTheFirstMemberOfAnOperation() throws {
        XCTAssertTrue(try makeCompleteOperation().input === inputSchema)
    }

    func test_input_throwsWhenTheSchemaIsNotAnOperation() {
        assertThrowsSchemaError(try makeStructure().input)
    }

    func test_input_throwsWhenTheOperationHasNoMembers() {
        assertThrowsSchemaError(try makeOperation(members: []).input)
    }

    func test_input_throwsWhenTheInputMemberHasNoTarget() {
        let operation = makeOperation(members: [
            makeMember("input", index: 0, target: nil),
            makeMember("output", index: 1, target: outputSchema),
        ])
        assertThrowsSchemaError(try operation.input)
    }

    // MARK: - output

    func test_output_returnsTheTargetOfTheSecondMemberOfAnOperation() throws {
        XCTAssertTrue(try makeCompleteOperation().output === outputSchema)
    }

    func test_output_throwsWhenTheSchemaIsNotAnOperation() {
        assertThrowsSchemaError(try makeStructure().output)
    }

    func test_output_throwsWhenTheOperationHasNoMembers() {
        assertThrowsSchemaError(try makeOperation(members: []).output)
    }

    func test_output_throwsWhenTheOperationHasOnlyAnInputMember() {
        let operation = makeOperation(members: [makeMember("input", index: 0, target: inputSchema)])
        assertThrowsSchemaError(try operation.output)
    }

    func test_output_throwsWhenTheOutputMemberHasNoTarget() {
        let operation = makeOperation(members: [
            makeMember("input", index: 0, target: inputSchema),
            makeMember("output", index: 1, target: nil),
        ])
        assertThrowsSchemaError(try operation.output)
    }
}
