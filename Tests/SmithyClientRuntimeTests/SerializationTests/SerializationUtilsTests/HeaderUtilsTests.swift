/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
import SmithyClientRuntime

class HeaderUtilsTests: XCTestCase {
    
    func testSplitHeaderListValues() {
        guard let headerCollectionValues = try! splitHeaderListValues("1") else {
            XCTFail("splitting header list values unexpectedly returned nil")
            return
        }
        XCTAssertEqual([1], headerCollectionValues.map { Int($0) })
        XCTAssertEqual([1, 2, 3], try! splitHeaderListValues("1,2,3")?.map { Int($0) })
        // Trim whitespaces in beginning and end of string components
        XCTAssertEqual([1, 2, 3], try! splitHeaderListValues(" 1, 2, 3 ")?.map { Int($0) })
        XCTAssertEqual([nil, 1], try! splitHeaderListValues(",1")?.map { Int($0) })
    }
    
    func testSplitHttpDateHeaderListValues() {
        let dateHeaderTransformations = [
            "Mon, 16 Dec 2019 23:48:18 GMT": ["Mon, 16 Dec 2019 23:48:18 GMT"],
            "Mon, 16 Dec 2019 23:48:18 GMT, Tue, 17 Dec 2019 23:48:18 GMT": [
                "Mon, 16 Dec 2019 23:48:18 GMT",
                "Tue, 17 Dec 2019 23:48:18 GMT"
            ],
            "": [""]
        ]
        
        for (headerListString, headerList) in dateHeaderTransformations {
            XCTAssertEqual(headerList, try! splitHttpDateHeaderListValues(headerListString))
        }
        
        XCTAssertThrowsError(try splitHttpDateHeaderListValues("Mon, 16 Dec 2019 23:48:18 GMT, , Tue, 17 Dec 2019 23:48:18 GMT")) { error in
            XCTAssertEqual("Invalid HTTP Header List with Timestamps: Mon, 16 Dec 2019 23:48:18 GMT, , Tue, 17 Dec 2019 23:48:18 GMT", error.localizedDescription)
        }
    }
    
    func testSplitBoolList() {
        XCTAssertEqual(["true", "false", "true", "true"], try! splitHeaderListValues("true,\"false\",true,\"true\""))
    }
    
    func testSplitIntList() {
        XCTAssertEqual(["1"], try! splitHeaderListValues("1"))
        XCTAssertEqual(["1", "2", "3"], try! splitHeaderListValues("1,2,3"))
        XCTAssertEqual(["1", "2", "3"], try! splitHeaderListValues("1,  2,  3"))
        
        // quoted
        XCTAssertEqual(["1", "2", "3", "-4", "5"], try! splitHeaderListValues("1,\"2\",3,\"-4\",5"))
    }
    
    func testSplitStringList() {
        XCTAssertEqual(["foo"], try! splitHeaderListValues("foo"))
        
        // trailing space
        XCTAssertEqual(["fooTrailing"], try! splitHeaderListValues("fooTrailing   "))
        
        // leading and trailing space
        XCTAssertEqual(["  foo  "], try! splitHeaderListValues("\"  foo  \""))
        
        // ignore spaces between values
        XCTAssertEqual(["foo", "bar"], try! splitHeaderListValues("foo  ,  bar"))
        XCTAssertEqual(["foo", "bar"], try! splitHeaderListValues("\"foo\"  ,  \"bar\""))
        
        // comma in quotes
        XCTAssertEqual(["foo,bar", "baz"], try! splitHeaderListValues("\"foo,bar\",baz"))
        
        // comm in quotes w/trailing space
        XCTAssertEqual(["foo,bar", "baz"], try! splitHeaderListValues("\"foo,bar\",baz  "))
        
        // quote in quotes
        XCTAssertEqual(["foo\",bar", "\"asdf\"", "baz"], try! splitHeaderListValues("\"foo\\\",bar\",\"\\\"asdf\\\"\",baz"))
        
        // quote in quote w/spaces
        XCTAssertEqual(["foo\",bar", "\"asdf  \"", "baz"], try! splitHeaderListValues("\"foo\\\",bar\", \"\\\"asdf  \\\"\", baz"))
        
        // empty quotes
        XCTAssertEqual(["", "baz"], try! splitHeaderListValues("\"\",baz"))
        
        // escaped slashes
        XCTAssertEqual(["foo", "(foo\\bar)"], try! splitHeaderListValues("foo, \"(foo\\\\bar)\""))
        
        // empty
        XCTAssertEqual(["", "1"], try! splitHeaderListValues(",1"))
        
        XCTAssertThrowsError(try splitHeaderListValues("foo, bar, \"baz")) { error in
            XCTAssertEqual("Invalid HTTP Header List with Strings: foo, bar, \"baz", error.localizedDescription)
        }
        
        XCTAssertThrowsError(try splitHeaderListValues("foo  ,  \"bar\"  \tf,baz")) { error in
            XCTAssertEqual("Invalid HTTP Header List with Strings: foo  ,  \"bar\"  \tf,baz", error.localizedDescription)
        }
    }
}
