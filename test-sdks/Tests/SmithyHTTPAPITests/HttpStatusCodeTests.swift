//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SmithyHTTPAPI

class HttpStatusCodeTests: XCTestCase {

    open func testHttpStatusCodeDescriptionWorks() {
        let httpStatusCode = HTTPStatusCode.ok
        let httpStatusCodeDescription = httpStatusCode.description

        XCTAssertNotNil(httpStatusCodeDescription)
    }
}
