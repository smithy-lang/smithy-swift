//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SmithyTestUtil
@testable import ClientRuntime

class SignerMiddlewareTests: XCTestCase {
    private var contextBuilder: HttpContextBuilder!
    private var operationStack: OperationStack<MockInput, MockOutput>!

    override func setUp() async throws {
        try await super.setUp()
        contextBuilder = HttpContextBuilder()
        operationStack = OperationStack<MockInput, MockOutput>(id: "auth scheme middleware test stack")
    }
    
    // Test exception cases
    func testNoSelectedAuthScheme() async throws {
        let context = contextBuilder.build()
        do {
            try await AssertRequestWasSigned(builtContext: context)
        } catch ClientError.authError(let message) {
            XCTAssertEqual(message, "Auth scheme needed by signer middleware was not saved properly.")
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }
    
    func testNoIdentityInSelectedAuthScheme() async throws {
        let context = contextBuilder
            .withSelectedAuthScheme(value: SelectedAuthScheme(
                schemeID: "mock",
                identity: nil,
                signingProperties: Attributes(),
                signer: MockSigner())
            )
            .build()
        do {
            try await AssertRequestWasSigned(builtContext: context)
        } catch ClientError.authError(let message) {
            XCTAssertEqual(message, "Identity needed by signer middleware was not properly saved into loaded auth scheme.")
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }
    
    func testNoSignerInSelectedAuthScheme() async throws {
        let context = contextBuilder
            .withSelectedAuthScheme(value: SelectedAuthScheme(
                schemeID: "mock",
                identity: MockIdentity(),
                signingProperties: Attributes(),
                signer: nil)
            )
            .build()
        do {
            try await AssertRequestWasSigned(builtContext: context)
        } catch ClientError.authError(let message) {
            XCTAssertEqual(message, "Signer needed by signer middleware was not properly saved into loaded auth scheme.")
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }
    
    func testNoSigningPropertiesInSelectedAuthScheme() async throws {
        let context = contextBuilder
            .withSelectedAuthScheme(value: SelectedAuthScheme(
                schemeID: "mock",
                identity: MockIdentity(),
                signingProperties: nil,
                signer: MockSigner())
            )
            .build()
        do {
            try await AssertRequestWasSigned(builtContext: context)
        } catch ClientError.authError(let message) {
            XCTAssertEqual(message, "Signing properties object needed by signer middleware was not properly saved into loaded auth scheme.")
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }
    
    // Test success cases
    func testSignedRequest() async throws {
        let context = contextBuilder
            .withSelectedAuthScheme(value: SelectedAuthScheme(
                schemeID: "mock",
                identity: MockIdentity(),
                signingProperties: Attributes(),
                signer: MockSigner())
            )
            .build()
        try await AssertRequestWasSigned(builtContext: context)
    }

    private func AssertRequestWasSigned(builtContext: HttpContext) async throws {
        operationStack.finalizeStep.intercept(position: .before, middleware: SignerMiddleware<MockOutput>())

        let mockHandler = MockHandler<MockOutput>(handleCallback: { (context, input) in
            XCTAssertEqual(input.headers.value(for: "Mock-Authorization"), "Mock-Signed")
            let httpResponse = HttpResponse(body: .noStream, statusCode: HttpStatusCode.ok)
            let mockOutput = MockOutput()
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse, output: mockOutput)
            return output
        })

        _ = try await operationStack.handleMiddleware(context: builtContext, input: MockInput(), next: mockHandler)
    }
}
