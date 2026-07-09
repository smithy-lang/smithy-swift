//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

final class SmithySwiftTests: XCTestCase {

    func test_itHasATestSuite() {
        // All of smithy-swift's test suite has been moved out to a subproject in test-sdks/.
        // Tests use SDKs generated from Smithy models, and the project containing those tests
        // will fail to `swift package resolve` if those test SDKs are not generated first.
        // Hence, those tests are moved to a subproject so this package will resolve successfully
        // on install with no setup required.
        //
        // To run the smithy-swift test suite, starting from the smithy-swift root directory, run:
        //
        // $ ./scripts/codegen.sh
        // $ cd test-sdks
        // $ swift test
        //
        // SDK generation requires any JDK ~17 already installed to run the code generator.
        //
        // This test serves the sole purpose of allowing the main smithy-swift project to
        // pass and succeed when it is tested.
    }
}
