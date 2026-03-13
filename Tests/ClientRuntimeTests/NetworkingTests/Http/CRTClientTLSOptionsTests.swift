//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime
import SmithyHTTPClientAPI

class CRTClientTLSOptionsTests: XCTestCase {
    
    func testMinimumTLSVersionInitialization() {
        let tlsOptions = CRTClientTLSOptions(minimumTLSVersion: .tls12)
        XCTAssertEqual(tlsOptions.minimumTLSVersion, .tls12)
    }
    
    func testMinimumTLSVersionDefaultsToNil() {
        let tlsOptions = CRTClientTLSOptions()
        XCTAssertNil(tlsOptions.minimumTLSVersion)
    }
    
    func testAllTLSVersionValues() {
        let tls10 = CRTClientTLSOptions(minimumTLSVersion: .tls10)
        let tls11 = CRTClientTLSOptions(minimumTLSVersion: .tls11)
        let tls12 = CRTClientTLSOptions(minimumTLSVersion: .tls12)
        let tls13 = CRTClientTLSOptions(minimumTLSVersion: .tls13)
        
        XCTAssertEqual(tls10.minimumTLSVersion, .tls10)
        XCTAssertEqual(tls11.minimumTLSVersion, .tls11)
        XCTAssertEqual(tls12.minimumTLSVersion, .tls12)
        XCTAssertEqual(tls13.minimumTLSVersion, .tls13)
    }
    
    func testResolveContextSucceedsWithMinimumTLSVersion() {
        let tlsOptions = CRTClientTLSOptions(minimumTLSVersion: .tls12)
        
        // The resolveContext() method should succeed without throwing
        let context = tlsOptions.resolveContext()
        
        // Verify a context was created
        XCTAssertNotNil(context)
    }

    func testResolveContextSucceedsWithAllTLSVersions() {
        let versions: [SmithyHTTPClientAPI.TLSVersion] = [.tls10, .tls11, .tls12, .tls13]
        
        for version in versions {
            let tlsOptions = CRTClientTLSOptions(minimumTLSVersion: version)
            let context = tlsOptions.resolveContext()
            
            XCTAssertNotNil(context, "Failed to create context for TLS version: \(version)")
        }
    }

    func testResolveContextSucceedsWithoutMinimumTLSVersion() {
        let tlsOptions = CRTClientTLSOptions()
        
        let context = tlsOptions.resolveContext()
        
        XCTAssertNotNil(context)
    }

}
