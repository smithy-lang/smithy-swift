//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import SmithyHTTPAuthAPI
import class Smithy.Context
import XCTest

/// A dummy resolver to exercise the AuthSchemeResolver extension
private struct DummyAuthSchemeResolver: AuthSchemeResolver {
    func resolveAuthScheme(params: AuthSchemeResolverParameters) throws -> [AuthOption] {
        // Not used in reprioritizeAuthOptions tests
        return []
    }

    func constructParameters(context: Context) throws -> AuthSchemeResolverParameters {
        // Not used in reprioritizeAuthOptions tests
        fatalError("constructParameters() is not implemented for tests")
    }
}

final class AuthSchemeResolverTests: XCTestCase {
    private var resolver: DummyAuthSchemeResolver!

    override func setUp() {
        super.setUp()
        resolver = DummyAuthSchemeResolver()
    }

    override func tearDown() {
        resolver = nil
        super.tearDown()
    }

    /// When no preference is provided, the order should remain unchanged
    func testNoPreference() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "smithy.api#noAuth")
        ]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: nil, authOptions: options)
        XCTAssertEqual(result.map { $0.schemeID }, options.map { $0.schemeID })
    }

    /// Preferred option should move to the front
    func testExactMatchAndOrder() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "smithy.api#noAuth")
        ]
        let preference = ["smithy.api#noAuth"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        let expectedOrder = ["smithy.api#noAuth", "aws.auth#sigv4"]
        XCTAssertEqual(result.map { $0.schemeID }, expectedOrder)
    }

    /// Preference without namespace prefix should still match
    func testNormalizedPreferenceWithoutPrefix() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "smithy.api#noAuth")
        ]
        let preference = ["sigv4"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        let expectedOrder = ["aws.auth#sigv4", "smithy.api#noAuth"]
        XCTAssertEqual(result.map { $0.schemeID }, expectedOrder)
    }

    /// Non-matching preferences should be ignored
    func testNonMatchingPreference() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "smithy.api#noAuth")
        ]
        let preference = ["unknownScheme"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        XCTAssertEqual(result.map { $0.schemeID }, options.map { $0.schemeID })
    }

    /// Duplicate preferences should include duplicates in the result
    func testMultiplePreferencesOrderAndDuplication() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "smithy.api#noAuth")
        ]
        let preference = ["noAuth", "sigv4", "sigv4"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        let expectedOrder = [
            "smithy.api#noAuth",  // match for "noAuth"
            "aws.auth#sigv4",     // first match for "sigv4"
            "aws.auth#sigv4"      // duplicate match for second "sigv4"
        ]
        XCTAssertEqual(result.map { $0.schemeID }, expectedOrder)
    }
}