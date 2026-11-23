//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
import Smithy
@_spi(SchemaBasedSerde)
import SmithyHTTPAPI
@_spi(SchemaBasedSerde)
import SmithySerialization

// Tests that `HTTPOperationExtension` resolves an operation's URI labels to its `@httpLabel` members,
// and reports a URI and input that disagree rather than sending a request with template text in its path.
//
// Generated models are validated by Smithy, so these operations are built by hand to reach the cases
// that a validated model can't produce.
final class HTTPOperationExtensionTests: XCTestCase {

    // MARK: - well-formed labels

    func test_labels_resolveEachLabelMemberToItsSegment() throws {
        let operation = try makeOperation(uri: "/{Bucket}/{Key+}", labels: ["Bucket", "Key"])

        let subject = try HTTPOperationExtension(schema: operation)

        // The path "/{Bucket}/{Key+}" splits into ["", "{Bucket}", "{Key+}"].
        XCTAssertEqual(subject.labelSegmentIndex, [1, 2])
        XCTAssertEqual(subject.labelIsGreedy, [false, true])
    }

    func test_labels_aMemberWithoutTheLabelTraitIsNotBound() throws {
        let operation = try makeOperation(uri: "/{Bucket}", labels: ["Bucket"], unbound: ["Other"])

        let subject = try HTTPOperationExtension(schema: operation)

        XCTAssertEqual(subject.labelSegmentIndex, [1, nil])
    }

    func test_labels_aLiteralQueryStringIsNotTreatedAsPartOfThePath() throws {
        let operation = try makeOperation(uri: "/{Bucket}?uploads", labels: ["Bucket"])

        let subject = try HTTPOperationExtension(schema: operation)

        XCTAssertEqual(subject.segments, ["", "{Bucket}"])
        XCTAssertEqual(subject.uriQueryItems.map(\.name), ["uploads"])
    }

    // MARK: - label serializer

    func test_labelSerializer_writesOnlyLabelMembersIntoThePath() throws {
        let operation = try makeOperation(uri: "/{Bucket}/fixed", labels: ["Bucket"], unbound: ["Bucket2"])
        let input = try operation.input
        let subject = HTTPLabelSerializer(operationExtension: try HTTPOperationExtension(schema: operation))

        try subject.writeString(input.members[0], "abc")
        // A member without the label trait is never written, even one whose name resembles a label.
        try subject.writeString(input.members[1], "dropped")

        XCTAssertEqual(subject.uri, "/abc/fixed")
    }

    // MARK: - URI and input that disagree

    func test_uriLabelWithNoMember_throws() throws {
        let operation = try makeOperation(uri: "/{Bucket}/{Missing}", labels: ["Bucket"])

        XCTAssertThrowsError(try HTTPOperationExtension(schema: operation)) { error in
            XCTAssertTrue(error is SerializerError, "\(error)")
        }
    }

    func test_uriLabelNamingAMemberWithoutTheLabelTrait_throws() throws {
        // The member exists, but isn't bound to a label, so the URI's label has nothing to fill it.
        let operation = try makeOperation(uri: "/{Bucket}", labels: [], unbound: ["Bucket"])

        XCTAssertThrowsError(try HTTPOperationExtension(schema: operation)) { error in
            XCTAssertTrue(error is SerializerError, "\(error)")
        }
    }

    func test_labelMemberWithNoURILabel_throws() throws {
        let operation = try makeOperation(uri: "/fixed", labels: ["Bucket"])

        XCTAssertThrowsError(try HTTPOperationExtension(schema: operation)) { error in
            XCTAssertTrue(error is SerializerError, "\(error)")
        }
    }

    // MARK: - malformed labels

    func test_malformedLabelSegments_throw() throws {
        let malformed = [
            "/{Bucket",      // unclosed
            "/Bucket}",      // unopened
            "/{Bucket}x",    // text after the label
            "/x{Bucket}",    // text before the label
            "/{}",           // no name
            "/{+}",          // greedy, but no name
            "/{Buc+ket}",    // '+' inside the name
            "/{{Bucket}}",   // nested braces
        ]
        for uri in malformed {
            let operation = try makeOperation(uri: uri, labels: ["Bucket"])

            XCTAssertThrowsError(try HTTPOperationExtension(schema: operation), uri) { error in
                XCTAssertTrue(error is SerializerError, "\(uri): \(error)")
            }
        }
    }

    // MARK: - Private methods

    /// Builds a GET operation with the passed URI, whose input has a string member for each passed name.
    ///
    /// Members named in `labels` carry the `httpLabel` trait; those in `unbound` carry no trait.
    private func makeOperation(uri: String, labels: [String], unbound: [String] = []) throws -> Schema {
        let labelTraits = TraitCollection(traits: [try HTTPLabelTrait(node: [:])])
        let names = labels.map { ($0, labelTraits) } + unbound.map { ($0, TraitCollection()) }
        let inputMembers = names.enumerated().map { index, member in
            Schema(
                id: ShapeID("ns.test", "OperationInput", member.0),
                type: .string,
                traits: member.1,
                containerType: .structure,
                index: index
            )
        }
        let input = Schema(id: ShapeID("ns.test", "OperationInput"), type: .structure, members: inputMembers)
        let output = Schema(id: ShapeID("ns.test", "OperationOutput"), type: .structure)
        let httpTrait = try HTTPTrait(node: ["method": "GET", "uri": .string(uri)])
        return Schema(
            id: ShapeID("ns.test", "Operation"),
            type: .operation,
            traits: TraitCollection(traits: [httpTrait]),
            members: [
                Schema(
                    id: ShapeID("ns.test", "Operation", "input"),
                    type: .structure,
                    containerType: .operation,
                    target: input,
                    index: 0
                ),
                Schema(
                    id: ShapeID("ns.test", "Operation", "output"),
                    type: .structure,
                    containerType: .operation,
                    target: output,
                    index: 1
                ),
            ]
        )
    }
}
