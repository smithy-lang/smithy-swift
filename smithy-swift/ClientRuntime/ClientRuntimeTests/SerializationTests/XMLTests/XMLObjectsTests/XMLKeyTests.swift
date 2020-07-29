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

class XMLKeyTests: XCTestCase {

    func testInitWithStringValue() {
        let key = XMLKey(stringValue: "foo")

        XCTAssertNotNil(key)
        XCTAssertEqual(key!.stringValue, "foo")
        XCTAssertEqual(key!.intValue, nil)
    }

    func testInitWithIntValue() {
        let key = XMLKey(intValue: 42)

        XCTAssertNotNil(key)
        XCTAssertEqual(key!.stringValue, "42")
        XCTAssertEqual(key!.intValue, 42)
    }

    func testInitWithStringValueIntValue() {
        let key = XMLKey(stringValue: "foo", intValue: 42)

        XCTAssertEqual(key.stringValue, "foo")
        XCTAssertEqual(key.intValue, 42)
    }
}
