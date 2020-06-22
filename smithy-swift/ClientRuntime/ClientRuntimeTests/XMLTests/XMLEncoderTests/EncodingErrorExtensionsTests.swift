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

class EncodingErrorExtensionsTests: XCTestCase {

    func testInvalidFloatingPointValueGivesInvalidValueError() {
        let invalidFloats = [Float.infinity, -Float.infinity, ]
        for invalidFloat in invalidFloats {
            let encodingError = EncodingError._invalidFloatingPointValue(invalidFloat, at: [dummyCodingKey()])
            if case let EncodingError.invalidValue(value, context) = encodingError {
                XCTAssertEqual(value as! Float, invalidFloat)
                XCTAssertNotNil(context.debugDescription)
            }
            else {
                XCTFail("invalid floats should throw EncodingError.invalidValue")
            }
        }
    }
    
    struct dummyCodingKey: CodingKey {
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "dummy"
        }
        
        init() {
            self.stringValue = "dummy"
        }
        
    }
}
