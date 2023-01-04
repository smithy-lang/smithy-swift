//  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//  SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCommonRuntimeKit
import AwsCCommon

open class CrtXCBaseTestCase: XCTestCase {
    let allocator = TracingAllocator(tracingStacksOf: defaultAllocator)
    let logging = Logger(pipe: stdout, level: .trace, allocator: defaultAllocator)

    open override func setUp() {
        super.setUp()

        CommonRuntimeKit.initialize(allocator: self.allocator)
    }

    open override func tearDown() {
        CommonRuntimeKit.cleanUp()

        allocator.dump()
        XCTAssertEqual(allocator.count, 0,
                       "Memory was leaked: \(allocator.bytes) bytes in \(allocator.count) allocations")

        super.tearDown()
    }
}
