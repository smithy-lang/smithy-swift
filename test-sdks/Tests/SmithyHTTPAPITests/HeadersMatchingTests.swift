//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI
import XCTest

/// Covers case-insensitive matching of header names, and lookup of names that are
/// stored more than once.
class HeadersMatchingTests: XCTestCase {

    // MARK: - values(for:) with repeated names
    //
    // `add` merges into an existing header, so duplicate case-insensitive names can only
    // arise from `addAll` — which is exactly what CRTClientEngine does when it folds
    // interim, main, and trailer headers into one response.

    func test_values_aggregatesAcrossHeadersRepeatedInDifferentCase() {
        var subject = Headers(["X-Foo": "1"])
        subject.addAll(headers: Headers(["x-foo": "2"]))
        subject.addAll(headers: Headers(["X-FOO": "3"]))

        XCTAssertEqual(subject.headers.count, 3)  // addAll appends without merging
        XCTAssertEqual(subject.values(for: "x-FoO"), ["1", "2", "3"])
        XCTAssertEqual(subject.value(for: "x-FoO"), "1,2,3")
    }

    func test_values_preservesInsertionOrderAcrossRepeatedNames() {
        var subject = Headers(["a": "z"])
        var other = Headers()
        other.add(name: "A", values: ["y", "x"])
        subject.addAll(headers: other)

        XCTAssertEqual(subject.values(for: "a"), ["z", "y", "x"])
    }

    func test_values_aggregatesWhenFirstMatchHasNoValues() {
        var subject = Headers(["a": []])
        var other = Headers()
        other.add(name: "A", value: "x")
        subject.addAll(headers: other)

        XCTAssertEqual(subject.values(for: "a"), ["x"])
    }

    func test_values_nilWhenNoHeaderMatches() {
        XCTAssertNil(Headers(["a": "x"]).values(for: "b"))
        XCTAssertNil(Headers().values(for: "a"))
    }

    // MARK: - Case-insensitive name matching

    func test_nameMatching_matchesRegardlessOfCase() {
        let subject = Headers(["Content-Type": "application/json"])
        for name in ["content-type", "CONTENT-TYPE", "Content-Type", "cOnTeNt-TyPe"] {
            XCTAssertTrue(subject.exists(name: name), "expected \(name) to match")
            XCTAssertEqual(subject.value(for: name), "application/json")
        }
    }

    func test_nameMatching_rejectsNamesOfDifferentLength() {
        let subject = Headers(["a": "x"])
        XCTAssertFalse(subject.exists(name: ""))
        XCTAssertFalse(subject.exists(name: "ab"))
        XCTAssertFalse(subject.exists(name: "a "))
    }

    func test_nameMatching_doesNotFoldNonAlphabeticAsciiThatDiffersByTheCaseBit() {
        // '_' (0x5F) and DEL (0x7F) differ only in bit 0x20, as do '[' (0x5B) and '{' (0x7B).
        // A fold that blindly ORs 0x20 would conflate them.
        let subject = Headers(["a_b": "x"])
        XCTAssertTrue(subject.exists(name: "A_B"))
        XCTAssertFalse(subject.exists(name: "a\u{7F}b"))

        let bracket = Headers(["a[b": "x"])
        XCTAssertFalse(bracket.exists(name: "a{b"))
    }

    func test_nameMatching_multiByteNameIsMatchedByteForByte() {
        // Field names are ASCII tokens per RFC 9110, so a non-ASCII name matches only itself.
        let subject = Headers(["x-café": "x"])
        XCTAssertTrue(subject.exists(name: "X-café"))
        XCTAssertFalse(subject.exists(name: "x-cafÉ"))
    }

    // MARK: - Mutations route through the same matching

    func test_add_mergesIntoExistingHeaderFoundInDifferentCase() {
        var subject = Headers(["X-Foo": "1"])
        subject.add(name: "x-foo", value: "2")

        XCTAssertEqual(subject.headers.count, 1)
        XCTAssertEqual(subject.headers[0].name, "X-Foo")  // original casing is kept
        XCTAssertEqual(subject.values(for: "X-Foo"), ["1", "2"])
    }

    func test_update_replacesHeaderFoundInDifferentCaseAndAdoptsTheNewName() {
        var subject = Headers(["X-Foo": "1"])
        subject.update(name: "x-foo", value: "2")

        XCTAssertEqual(subject.headers.count, 1)
        XCTAssertEqual(subject.headers[0].name, "x-foo")
        XCTAssertEqual(subject.values(for: "X-FOO"), ["2"])
    }

    func test_remove_removesOnlyTheFirstMatchWhenNameIsRepeated() {
        var subject = Headers(["X-Foo": "1"])
        var other = Headers()
        other.add(name: "x-foo", value: "2")
        subject.addAll(headers: other)

        subject.remove(name: "X-FOO")

        XCTAssertEqual(subject.values(for: "x-foo"), ["2"])
    }
}
