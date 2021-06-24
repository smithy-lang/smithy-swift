import XCTest

import ClientRuntimeTests
import SmithyTestUtilTests

var tests = [XCTestCaseEntry]()
tests += ClientRuntimeTests.__allTests()
tests += SmithyTestUtilTests.__allTests()

XCTMain(tests)
