//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import ClientRuntime

final class EndpointsAuthSchemeResolverTests: XCTestCase {
    func testParsing() throws {
        let sigV4 = [
            "signingRegion": "us-west-2",
            "name": "sigv4",
            "signingName": "s3",
            "disableDoubleEncoding": true
        ] as [String: AnyHashable]

        let actualSigV4 = try EndpointsAuthScheme(from: sigV4)
        if case let .sigV4(data) = actualSigV4 {
            XCTAssertEqual(data.signingName, "s3")
            XCTAssertEqual(data.signingRegion, "us-west-2")
            XCTAssertEqual(data.disableDoubleEncoding, true)
        } else {
            XCTFail("Failed to decode sigv4")
        }

        let sigV4A = [
            "signingRegionSet": [
                "*"
            ],
            "name": "sigv4a",
            "signingName": "s3",
            "disableDoubleEncoding": true
        ] as [String: AnyHashable]

        let actualSigV4a = try EndpointsAuthScheme(from: sigV4A)
        if case let .sigV4A(data) = actualSigV4a {
            XCTAssertEqual(data.signingName, "s3")
            XCTAssertEqual(data.signingRegionSet, ["*"])
            XCTAssertEqual(data.disableDoubleEncoding, true)
        } else {
            XCTFail("Failed to decode sigv4a")
        }
    }

    func testResolve_givenSupportedScheme_returnsScheme() throws {
        let resolver = DefaultEndpointsAuthSchemeResolver(supportedAuthSchemes: ["sigv4"])
        let sigV4 = EndpointsAuthScheme.sigV4(EndpointsAuthScheme.SigV4Parameters(signingName: nil, signingRegion: nil, disableDoubleEncoding: nil))
        let sigV4A = EndpointsAuthScheme.sigV4A(.init(signingName: nil, signingRegionSet: nil, disableDoubleEncoding: nil))
        let none = EndpointsAuthScheme.none

        let actualSigV4 = try resolver.resolve(authSchemes: [sigV4, sigV4A, none])
        XCTAssertEqual(actualSigV4, sigV4)

        let actualSigV4A = try resolver.resolve(authSchemes: [sigV4A, sigV4, none])
        XCTAssertEqual(actualSigV4A, sigV4)

        let actualNone = try resolver.resolve(authSchemes: [none, sigV4A, sigV4])
        XCTAssertEqual(actualNone, sigV4)
    }

    func testResolve_givenUnsupportedScheme_returnsNil() throws {
        let resolver = DefaultEndpointsAuthSchemeResolver(supportedAuthSchemes: ["sigv4"])
        let sigV4A = EndpointsAuthScheme.sigV4A(.init(signingName: nil, signingRegionSet: nil, disableDoubleEncoding: nil))
        let none = EndpointsAuthScheme.none

        XCTAssertThrowsError(try resolver.resolve(authSchemes: [sigV4A, none]))

        XCTAssertThrowsError(try resolver.resolve(authSchemes: [none, sigV4A]))
    }
}