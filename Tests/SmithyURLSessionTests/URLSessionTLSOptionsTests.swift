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

class URLSessionTLSOptionsTests: XCTestCase {
    
    func testMinimumTLSVersionInitialization() {
        let tlsOptions = URLSessionTLSOptions(minimumTLSVersion: .tls12)
        XCTAssertEqual(tlsOptions.minimumTLSVersion, .tls12)
    }
    
    func testMinimumTLSVersionDefaultsToNil() {
        let tlsOptions = URLSessionTLSOptions()
        XCTAssertNil(tlsOptions.minimumTLSVersion)
    }
    
    func testAllTLSVersionValues() {
        let tls10 = URLSessionTLSOptions(minimumTLSVersion: .tls10)
        let tls11 = URLSessionTLSOptions(minimumTLSVersion: .tls11)
        let tls12 = URLSessionTLSOptions(minimumTLSVersion: .tls12)
        let tls13 = URLSessionTLSOptions(minimumTLSVersion: .tls13)
        
        XCTAssertEqual(tls10.minimumTLSVersion, .tls10)
        XCTAssertEqual(tls11.minimumTLSVersion, .tls11)
        XCTAssertEqual(tls12.minimumTLSVersion, .tls12)
        XCTAssertEqual(tls13.minimumTLSVersion, .tls13)
    }
}
