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
        let next = MockHandler<TestInputType, TestOutputType> { (context, input) in
            XCTAssertEqual(input.tokenMember, self.token)
        }
        _ = try await subject.handle(context: context, input: input, next: next)
    }

    func test_handle_itDoesNotChangeTheIdempotencyTokenIfAlreadySet() async throws {
        let input = TestInputType(tokenMember: previousToken)
        let next = MockHandler<TestInputType, TestOutputType> { (context, input) in
            XCTAssertEqual(input.tokenMember, self.previousToken)
        }
        _ = try await subject.handle(context: context, input: input, next: next)
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

private struct MockHandler<I, O>: Handler {
    typealias Output = OperationOutput<O>
    typealias MockHandlerCallback = (Context, I) async throws -> Void

    private let handleCallback: MockHandlerCallback

    init(handleCallback: @escaping MockHandlerCallback) {
        self.handleCallback = handleCallback
    }

    func handle(context: Context, input: I) async throws -> Output {
        try await handleCallback(context, input)
        return OperationOutput(httpResponse: HttpResponse())
    }
}
