//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import SmithyHTTPAPI

final class URLEncodingUtilsTests: XCTestCase {

    /// The characters that are never percent-escaped, spelled out independently of the
    /// implementation so that a change to the implementation's allowed set fails these tests.
    ///
    /// This is the RFC 3986 unreserved set:
    /// https://www.rfc-editor.org/rfc/rfc3986#section-2.3
    private let unreserved = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    // MARK: - the allowed set, over all of ASCII

    func test_forQuery_escapesEveryASCIICharacterOutsideTheUnreservedSet() {
        for scalarValue in 0..<128 {
            let scalar = UnicodeScalar(UInt8(scalarValue))
            let input = String(scalar)
            let expected = unreserved.contains(Character(scalar)) ? input : percentEscape(scalarValue)

            XCTAssertEqual(
                URLEncodingUtils.urlPercentEncodedForQuery(input),
                expected,
                "ASCII \(scalarValue) (\(input.debugDescription)) encoded incorrectly for a query"
            )
        }
    }

    func test_forPath_escapesEveryASCIICharacterOutsideTheUnreservedSetExceptForwardSlash() {
        for scalarValue in 0..<128 {
            let scalar = UnicodeScalar(UInt8(scalarValue))
            let input = String(scalar)
            let isAllowed = unreserved.contains(Character(scalar)) || scalar == "/"
            let expected = isAllowed ? input : percentEscape(scalarValue)

            XCTAssertEqual(
                URLEncodingUtils.urlPercentEncodedForPath(input),
                expected,
                "ASCII \(scalarValue) (\(input.debugDescription)) encoded incorrectly for a path"
            )
        }
    }

    /// Renders the expected escape for a byte, independently of the implementation's hex table.
    private func percentEscape(_ byte: Int) -> String {
        String(format: "%%%02X", byte)
    }

    // MARK: - forward slash

    func test_forwardSlash_isKeptForAPathAndEscapedForAQuery() {
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForPath("a/b/c"), "a/b/c")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("a/b/c"), "a%2Fb%2Fc")
    }

    // MARK: - percent escapes are rendered with uppercase hex

    func test_escapes_useUppercaseHexDigits() {
        // Lowercase hex is legal in a URL but is not what SigV4 canonicalization expects.
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("/"), "%2F")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery(":"), "%3A")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("\u{7F}"), "%7F")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("é"), "%C3%A9")
    }

    // MARK: - the percent sign itself

    func test_percentSign_isItselfEscapedSoEncodingIsNotIdempotent() {
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("%"), "%25")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("100%"), "100%25")

        // An already-encoded string encodes again; callers must not double-encode.
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("%2F"), "%252F")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForPath("%2F"), "%252F")
    }

    // MARK: - multi-byte UTF-8

    func test_multibyteUTF8_escapesEveryByteOfTheSequence() {
        // Two-byte sequence.
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("café"), "caf%C3%A9")
        // Three-byte sequences.
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("日本"), "%E6%97%A5%E6%9C%AC")
        // Four-byte sequence, i.e. a scalar outside the basic multilingual plane.
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("😀"), "%F0%9F%98%80")
        // A non-ASCII digit is escaped, even though it is a Unicode number.
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("٣"), "%D9%A3")
    }

    func test_multibyteUTF8_isNotNormalizedBeforeEncoding() {
        // The same character, precomposed and then decomposed, encodes differently.
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("\u{00E9}"), "%C3%A9")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("e\u{0301}"), "e%CC%81")
    }

    // MARK: - control characters

    func test_controlCharacters_areEscaped() {
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery("\u{00}\n\r\t\u{7F}"), "%00%0A%0D%09%7F")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForPath("\u{00}\n\r\t\u{7F}"), "%00%0A%0D%09%7F")
    }

    // MARK: - inputs that need no escaping

    func test_emptyString_encodesToEmptyString() {
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery(""), "")
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForPath(""), "")
    }

    func test_unreservedString_isReturnedUnchanged() {
        let unescaped = "abcXYZ012_-.~"
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForQuery(unescaped), unescaped)
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForPath(unescaped), unescaped)

        // A path additionally passes through joined segments untouched.
        XCTAssertEqual(URLEncodingUtils.urlPercentEncodedForPath("/2016-03-11/pipeline/my-pipeline"),
                       "/2016-03-11/pipeline/my-pipeline")
    }

    // MARK: - long inputs

    func test_longFullyEscapedString_encodesEveryCharacter() {
        let count = 5000
        let input = String(repeating: " ", count: count)

        let encoded = URLEncodingUtils.urlPercentEncodedForQuery(input)

        // Each escape is three bytes wide, so the result is exactly three times as long.
        XCTAssertEqual(encoded.count, 3 * count)
        XCTAssertEqual(encoded, String(repeating: "%20", count: count))
    }

    func test_longPartiallyEscapedString_encodesOnlyTheDisallowedCharacters() {
        let input = String(repeating: "aA0_-.~/ ", count: 1000)

        let encoded = URLEncodingUtils.urlPercentEncodedForPath(input)

        XCTAssertEqual(encoded, String(repeating: "aA0_-.~/%20", count: 1000))
    }

    // MARK: - encodeNumber

    func test_encodeNumber_rendersNonFiniteDoublesUsingSmithyTokens() {
        XCTAssertEqual(URLEncodingUtils.encodeNumber(Double.nan), "NaN")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(Double.signalingNaN), "NaN")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(Double.infinity), "Infinity")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(-Double.infinity), "-Infinity")
    }

    func test_encodeNumber_rendersNonFiniteFloatsUsingSmithyTokens() {
        XCTAssertEqual(URLEncodingUtils.encodeNumber(Float.nan), "NaN")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(Float.signalingNaN), "NaN")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(Float.infinity), "Infinity")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(-Float.infinity), "-Infinity")
    }

    func test_encodeNumber_rendersNegativeNaNWithoutASign() {
        // A NaN has a sign bit, and interpolating it directly would render "-nan".
        XCTAssertEqual(URLEncodingUtils.encodeNumber(-Double.nan), "NaN")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(-Float.nan), "NaN")
    }

    func test_encodeNumber_rendersFiniteValues() {
        XCTAssertEqual(URLEncodingUtils.encodeNumber(Double(3)), "3.0")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(Float(3)), "3.0")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(2.25), "2.25")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(-42.5), "-42.5")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(0.0), "0.0")
        XCTAssertEqual(URLEncodingUtils.encodeNumber(-0.0), "-0.0")
    }
}
