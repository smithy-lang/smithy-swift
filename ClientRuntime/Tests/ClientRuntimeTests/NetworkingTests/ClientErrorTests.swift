//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import XCTest
@testable import ClientRuntime

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
