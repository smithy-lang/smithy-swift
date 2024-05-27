//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import SmithyHTTPAuthAPI
import SmithyIdentityAPI
import XCTest
import SmithyTestUtil
@testable import ClientRuntime

class AuthSchemeMiddlewareTests: XCTestCase {
    private var contextBuilder: ContextBuilder!
    private var operationStack: OperationStack<MockInput, MockOutput>!

    override func setUp() async throws {
        try await super.setUp()
        contextBuilder = ContextBuilder()
            .withAuthSchemeResolver(value: DefaultMockAuthSchemeResolver())
            .withAuthScheme(value: MockNoAuth())
            .withIdentityResolver(value: MockIdentityResolver(), schemeID: "MockAuthSchemeA")
            .withIdentityResolver(value: MockIdentityResolver(), schemeID: "MockAuthSchemeB")
            .withIdentityResolver(value: MockIdentityResolver(), schemeID: "MockAuthSchemeC")
        operationStack = OperationStack<MockInput, MockOutput>(id: "auth scheme middleware test stack")
    }

    // Test exception cases
    func testNoAuthSchemeResolverConfigured() async throws {
        contextBuilder.withAuthSchemeResolver(value: nil)
        contextBuilder.withOperation(value: "fillerOp")
        do {
            try await AssertSelectedAuthSchemeMatches(builtContext: contextBuilder.build(), expectedAuthScheme: "")
        } catch ClientError.authError(let message) {
            let expected = "No auth scheme resolver has been configured on the service."
            XCTAssertEqual(message, expected)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    func testNoIdentityResolverConfigured() async throws {
        contextBuilder.removeIdentityResolvers()
        contextBuilder.withOperation(value: "fillerOp")
        do {
            try await AssertSelectedAuthSchemeMatches(builtContext: contextBuilder.build(), expectedAuthScheme: "")
        } catch ClientError.authError(let message) {
            let expected = "No identity resolver has been configured on the service."
            XCTAssertEqual(message, expected)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    func testNoAuthSchemeCouldBeLoaded() async throws {
        contextBuilder.withOperation(value: "fillerOp")
        do {
            try await AssertSelectedAuthSchemeMatches(builtContext: contextBuilder.build(), expectedAuthScheme: "")
        } catch ClientError.authError(let message) {
            let expected = "Could not resolve auth scheme for the operation call. Log: Auth scheme fillerAuth was not enabled for this request."
            XCTAssertEqual(message, expected)
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    // Test success cases
    func testOnlyAuthSchemeA() async throws {
        let context = contextBuilder
            .withOperation(value: "authA")
            .withAuthScheme(value: MockAuthSchemeA())
            .build()
        try await AssertSelectedAuthSchemeMatches(builtContext: context, expectedAuthScheme: "MockAuthSchemeA")
    }

    func testAuthOrderABSelectA() async throws {
        let context = contextBuilder
            .withOperation(value: "authAB")
            .withAuthScheme(value: MockAuthSchemeA())
            .withAuthScheme(value: MockAuthSchemeB())
            .build()
        try await AssertSelectedAuthSchemeMatches(builtContext: context, expectedAuthScheme: "MockAuthSchemeA")
    }

    func testAuthOrderABSelectB() async throws {
        let context = contextBuilder
            .withOperation(value: "authAB")
            .withAuthScheme(value: MockAuthSchemeB())
            .build()
        try await AssertSelectedAuthSchemeMatches(builtContext: context, expectedAuthScheme: "MockAuthSchemeB")
    }

    func testAuthOrderABCSelectA() async throws {
        let context = contextBuilder
            .withOperation(value: "authABC")
            .withAuthScheme(value: MockAuthSchemeA())
            .withAuthScheme(value: MockAuthSchemeB())
            .withAuthScheme(value: MockAuthSchemeC())
            .build()
        try await AssertSelectedAuthSchemeMatches(builtContext: context, expectedAuthScheme: "MockAuthSchemeA")
    }

    func testAuthOrderABCSelectB() async throws {
        let context = contextBuilder
            .withOperation(value: "authABC")
            .withAuthScheme(value: MockAuthSchemeB())
            .withAuthScheme(value: MockAuthSchemeC())
            .build()
        try await AssertSelectedAuthSchemeMatches(builtContext: context, expectedAuthScheme: "MockAuthSchemeB")
    }

    func testAuthOrderABCSelectC() async throws {
        let context = contextBuilder
            .withOperation(value: "authABC")
            .withAuthScheme(value: MockAuthSchemeC())
            .build()
        try await AssertSelectedAuthSchemeMatches(builtContext: context, expectedAuthScheme: "MockAuthSchemeC")
    }

    func testAuthOrderABCNoAuthSelectNoAuth() async throws {
        let context = contextBuilder
            .withOperation(value: "authABCNoAuth")
            .build()
        try await AssertSelectedAuthSchemeMatches(builtContext: context, expectedAuthScheme: "smithy.api#noAuth")
    }

    private func AssertSelectedAuthSchemeMatches(
        builtContext: Context,
        expectedAuthScheme: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        operationStack.buildStep.intercept(position: .before, middleware: AuthSchemeMiddleware<MockOutput>())

        let mockHandler = MockHandler<MockOutput>(handleCallback: { (context, input) in
            let selectedAuthScheme = context.selectedAuthScheme
            XCTAssertEqual(expectedAuthScheme, selectedAuthScheme?.schemeID, file: file, line: line)
            let httpResponse = HttpResponse(body: .noStream, statusCode: HttpStatusCode.ok)
            let mockOutput = MockOutput()
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse, output: mockOutput)
            return output
        })

        _ = try await operationStack.handleMiddleware(context: builtContext, input: MockInput(), next: mockHandler)
    }
}
