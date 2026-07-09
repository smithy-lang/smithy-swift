//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

final class SmithySwiftTests: XCTestCase {

    func test_itHasATestSuite() {
        // All of smithy-swift's test suite has been moved out to a subproject.
        // Tests use SDKs generated from Smithy models, and SDK generation requires
        // any JDK ~17 to run the code generator.
        // From the smithy-swift root directory, run:
        //
        // $ ./scripts/codegen.sh
        // $ cd test-sdks
        // $ swift test
        //
        // This test serves the sole purpose of having the main smithy-swift project
        // pass when it is tested.
    }
}
