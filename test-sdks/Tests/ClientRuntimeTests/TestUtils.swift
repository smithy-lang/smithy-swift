//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

/// An async version of `XCTAssertThrowsError`.
func XCTAssertThrowsErrorAsync(
    _ exp: @autoclosure () async throws -> Void,
    _ block: (Error) -> Void
) async {
    do {
        try await exp()
        XCTFail("Should have thrown error")
    } catch {
        block(error)
    }
}
