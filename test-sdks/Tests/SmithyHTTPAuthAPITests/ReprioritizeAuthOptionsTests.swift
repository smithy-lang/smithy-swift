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

    // Manual Auth Schemes Configuration Tests

    /// Row 1: Supported Auth contains sigv4 and sigv4a, service trait contains sigv4 and sigv4a
    func testManualConfigRow1() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "aws.auth#sigv4a")
        ]

        // No preference list - should maintain original order
        let resultNoPreference = resolver.reprioritizeAuthOptions(authSchemePreference: nil, authOptions: options)
        XCTAssertEqual(resultNoPreference.map { $0.schemeID }, ["aws.auth#sigv4", "aws.auth#sigv4a"])

        // Empty preference list - should maintain original order
        let resultEmptyPreference = resolver.reprioritizeAuthOptions(authSchemePreference: [], authOptions: options)
        XCTAssertEqual(resultEmptyPreference.map { $0.schemeID }, ["aws.auth#sigv4", "aws.auth#sigv4a"])

        // Resolved auth should be sigv4
        let preference = ["sigv4"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        XCTAssertEqual(result.first?.schemeID, "aws.auth#sigv4")
    }

    /// Row 2: Service trait has sigv4, sigv4a; preference list has sigv4a
    func testManualConfigRow2() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "aws.auth#sigv4a")
        ]
        let preference = ["sigv4a"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        XCTAssertEqual(result.first?.schemeID, "aws.auth#sigv4a")
    }

    /// Row 3: Service trait has sigv4, sigv4a; preference list has sigv4a, sigv4
    func testManualConfigRow3() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "aws.auth#sigv4a")
        ]
        let preference = ["sigv4a", "sigv4"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        let expectedOrder = ["aws.auth#sigv4a", "aws.auth#sigv4"]
        XCTAssertEqual(result.map { $0.schemeID }, expectedOrder)
    }

    /// Row 4: Service trait has only sigv4; preference list has sigv4a
    func testManualConfigRow4() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4")
        ]
        let preference = ["sigv4a"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        // Since sigv4a is not available, should return sigv4
        XCTAssertEqual(result.map { $0.schemeID }, ["aws.auth#sigv4"])
    }

    /// Row 5: Service trait has sigv4, sigv4a; operation trait has sigv4
    func testManualConfigRow5() {
        // When operation trait specifies sigv4, only sigv4 should be available
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4")
        ]
        let preference = ["sigv4a"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        XCTAssertEqual(result.map { $0.schemeID }, ["aws.auth#sigv4"])
    }

    /// Row 6: Service trait has sigv4, sigv4a; preference list has sigv4a
    func testManualConfigRow6() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "aws.auth#sigv4a")
        ]
        let preference = ["sigv4a"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        XCTAssertEqual(result.first?.schemeID, "aws.auth#sigv4a")
    }

    /// Row 7: Service trait has sigv4, sigv4a; preference list has sigv3
    func testManualConfigRow7() {
        let options = [
            AuthOption(schemeID: "aws.auth#sigv4"),
            AuthOption(schemeID: "aws.auth#sigv4a")
        ]
        let preference = ["sigv3"]
        let result = resolver.reprioritizeAuthOptions(authSchemePreference: preference, authOptions: options)
        // Since sigv3 is not available, should maintain original order
        XCTAssertEqual(result.map { $0.schemeID }, ["aws.auth#sigv4", "aws.auth#sigv4a"])
    }
}