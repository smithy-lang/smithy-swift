//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Testing
import XCTest

/// Reports test failures to whichever test framework is running the test.
///
/// Lets the protocol test assertion logic be shared between XCTest-based and Swift Testing-based tests.
struct TestFailureReporter {
    let report: (String) -> Void

    /// Reports failures with `XCTFail`, at the passed file & line.
    static func xcTest(file: StaticString, line: UInt) -> TestFailureReporter {
        TestFailureReporter { XCTFail($0, file: file, line: line) }
    }

    /// Reports failures as a Swift Testing `Issue`, at the passed source location.
    static func swiftTesting(_ sourceLocation: SourceLocation) -> TestFailureReporter {
        TestFailureReporter { Issue.record(Comment(rawValue: $0), sourceLocation: sourceLocation) }
    }

    func fail(_ message: String) {
        report(message)
    }

    func check(_ condition: Bool, _ message: @autoclosure () -> String) {
        if !condition { report(message()) }
    }

    func checkEqual<T: Equatable>(_ expected: T, _ actual: T, _ label: String) {
        if expected != actual {
            let expected = String(describing: expected)
            let actual = String(describing: actual)
            report("\(label) does not match.  Expected: \(expected)  Actual: \(actual)")
        }
    }
}
