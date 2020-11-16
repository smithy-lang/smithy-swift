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
import ClientRuntime

class HeaderUtilsTests: XCTestCase {
    
    func testSplitHeaderListValues() {
        guard let headerCollectionValues = splitHeaderListValues("1") else {
            XCTFail("splitting header list values unexpectedly returned nil")
            return
        }
        XCTAssertEqual([1], headerCollectionValues.map { Int($0) })
        XCTAssertEqual([1, 2, 3], splitHeaderListValues("1,2,3")?.map { Int($0) })
        // Trim whitespaces in beginning and end of string components
        XCTAssertEqual([1, 2, 3], splitHeaderListValues(" 1, 2, 3 ")?.map { Int($0) })
        XCTAssertEqual([nil, 1], splitHeaderListValues(",1")?.map { Int($0) })
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
            XCTAssertEqual(headerList, try? splitHttpDateHeaderListValues(headerListString))
        }
        
        let invalidTimestampHeaderListString = "Mon, 16 Dec 2019 23:48:18 GMT, , Tue, 17 Dec 2019 23:48:18 GMT"
        XCTAssertThrowsError(try splitHttpDateHeaderListValues(invalidTimestampHeaderListString)) { error in
            XCTAssertEqual(ClientError.deserializationFailed(HeaderDeserializationError.invalidTimestampHeaderList(value: invalidTimestampHeaderListString)),
                           error as? ClientError)
        }
    }

}
