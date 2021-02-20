/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class EncodingErrorExtensionsTests: XCTestCase {

    func testInvalidFloatingPointValueGivesInvalidValueError() {
        let invalidFloats = [Float.infinity, -Float.infinity ]
        for invalidFloat in invalidFloats {
            let encodingError = EncodingError._invalidFloatingPointValue(invalidFloat, at: [DummyCodingKey()])
            if case let EncodingError.invalidValue(value, context) = encodingError {
                XCTAssertEqual(value as? Float, invalidFloat)
                XCTAssertNotNil(context.debugDescription)
            } else {
                XCTFail("invalid floats should throw EncodingError.invalidValue")
            }
        }
    }

    struct DummyCodingKey: CodingKey {
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
