//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime
import XCTest

class IdempotencyTokenMiddlewareTests: XCTestCase {

    private typealias Subject = IdempotencyTokenMiddleware<TestInputType, TestOutputType>

    let token = "def"
    let previousToken = "abc"
    private var tokenGenerator: IdempotencyTokenGenerator!
    private var context: HttpContext!
    private var subject: Subject!

    override func setUp() async throws {
        try await super.setUp()
        tokenGenerator = TestIdempotencyTokenGenerator(token: token)
        context = HttpContextBuilder().withIdempotencyTokenGenerator(value: tokenGenerator).build()
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

private struct TestOutputType {
//    init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder?) async throws {
//        // no-op
//    }
}

//private enum TestOutputErrorType: HttpResponseErrorBinding {
//    static func makeError(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder?) async throws -> Error {
//        return TestError()
//    }
//}

private struct TestError: Error {}

private struct MockHandler<I, O>: Handler {
    typealias Output = OperationOutput<O>
    typealias Context = HttpContext
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
