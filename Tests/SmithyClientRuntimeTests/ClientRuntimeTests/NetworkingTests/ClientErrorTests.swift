/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import SmithyClientRuntime

class ClientErrorTests: XCTestCase {
    
    func testNetworkErrorInEqualityWithoutDescription() throws {
        enum NetworkError: Error {
          case actual
          case expected
        }
        let actualNetworkError = ClientError.networkError(NetworkError.actual)
        let expectedNetworkError = ClientError.networkError(NetworkError.expected)
        
        XCTAssertNotEqual(actualNetworkError, expectedNetworkError)
    }
    
    func testNetworkErrorInEqualityWithDescription() throws {
        enum NetworkError: Error, CustomStringConvertible {
          case actual
          case expected
        
          var description: String {
            switch self {
            case .actual:
                return "Actual"
            case .expected:
                return "Expected"
            }
          }
        }
        
        let actualNetworkError = ClientError.networkError(NetworkError.actual)
        let expectedNetworkError = ClientError.networkError(NetworkError.expected)
        
        XCTAssertNotEqual(actualNetworkError, expectedNetworkError)
    }
    
    func testNetworkErrorEqualityWithDescription() throws {
        enum NetworkError: Error, CustomStringConvertible {
          case actual
          case actualCopy
        
          var description: String {
            switch self {
            case .actual:
                return "Actual"
            case .actualCopy:
                return "Actual"
            }
          }
        }
        
        let actualNetworkError = ClientError.networkError(NetworkError.actual)
        let actualCopyNetworkError = ClientError.networkError(NetworkError.actualCopy)
        
        XCTAssertEqual(actualNetworkError, actualCopyNetworkError)
    }
}
