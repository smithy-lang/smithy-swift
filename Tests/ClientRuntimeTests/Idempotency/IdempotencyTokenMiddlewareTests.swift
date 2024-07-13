//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import Foundation
import ClientRuntime
import XCTest

class IdempotencyTokenMiddlewareTests: XCTestCase {

    private typealias Subject = IdempotencyTokenMiddleware<TestInputType, TestOutputType>

    let token = "def"
    let previousToken = "abc"
    private var tokenGenerator: IdempotencyTokenGenerator!
    private var context: Context!
    private var subject: Subject!

    override func setUp() async throws {
        try await super.setUp()
        tokenGenerator = TestIdempotencyTokenGenerator(token: token)
        context = ContextBuilder().withIdempotencyTokenGenerator(value: tokenGenerator).build()
        subject = Subject(keyPath: \.tokenMember)
    }

    func test_handle_itSetsAnIdempotencyTokenIfNoneIsSet() async throws {
        let input = TestInputType(tokenMember: nil)
        let ctx = DefaultInterceptorContext<TestInputType, TestOutputType, HTTPRequest, HTTPResponse>(input: input, attributes: context)
        try await subject.modifyBeforeSerialization(context: ctx)

        XCTAssertEqual(ctx.getInput().tokenMember, self.token)
    }

    func test_handle_itDoesNotChangeTheIdempotencyTokenIfAlreadySet() async throws {
        let input = TestInputType(tokenMember: previousToken)
        let ctx = DefaultInterceptorContext<TestInputType, TestOutputType, HTTPRequest, HTTPResponse>(input: input, attributes: context)
        try await subject.modifyBeforeSerialization(context: ctx)

        XCTAssertEqual(ctx.getInput().tokenMember, self.previousToken)
    }
}

// MARK: - Test fixtures & types

private struct TestIdempotencyTokenGenerator: IdempotencyTokenGenerator {
    let token: String
    func generateToken() -> String { token }
}

private struct TestInputType {
    var tokenMember: String?
}

private struct TestOutputType {}
