// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import XCTest
import SmithyTestUtil
@testable import ClientRuntime

class ContentLengthMiddlewareTests: XCTestCase {
    private var builtContext: HttpContext!
    private var stack: OperationStack<MockInput, MockOutput>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        builtContext = HttpContextBuilder()
                  .withMethod(value: .get)
                  .withPath(value: "/")
                  .withEncoder(value: JSONEncoder())
                  .withDecoder(value: JSONDecoder())
                  .withOperation(value: "Test Operation")
                  .build()
        stack = OperationStack<MockInput, MockOutput>(id: "Test Operation")
    }

    func testTransferEncodingChunkedSetWhenStreamLengthIsNil() async throws {
        addContentLengthMiddlewareWith(requiresLength: false, unsignedPayload: true)
        forceEmptyStream()
        try await AssertHeadersArePresent(expectedHeaders: ["Transfer-Encoding": "chunked"])
    }

    func testTransferEncodingChunkedSetWithNilTraits() async throws {
        // default constructor
        addContentLengthMiddlewareWith(requiresLength: nil, unsignedPayload: nil)
        forceEmptyStream()
        try await AssertHeadersArePresent(expectedHeaders: ["Transfer-Encoding": "chunked"])
    }

    func testContentLengthSetWhenStreamLengthAvailableAndRequiresLengthSet() async throws {
        addContentLengthMiddlewareWith(requiresLength: true, unsignedPayload: false)
        try await AssertHeadersArePresent(expectedHeaders: ["Content-Length": "0"])
    }

    func testContentLengthSetWhenRequiresLengthAndUnsignedPayload() async throws {
        addContentLengthMiddlewareWith(requiresLength: true, unsignedPayload: true)
        try await AssertHeadersArePresent(expectedHeaders: ["Content-Length": "0"])
    }

    func testRequiresLengthSetWithNilStreamShouldThrowError() async throws {
        addContentLengthMiddlewareWith(requiresLength: true, unsignedPayload: false)
        forceEmptyStream()
        do {
            try await AssertHeadersArePresent(expectedHeaders: ["Content-Length": "0"])
            XCTFail("Should throw error")
        } catch let error as StreamError {
            switch error {
            case .notSupported("Missing content-length for SigV4 signing on operation: Test Operation"), .notSupported("Missing content-length for operation: Test Operation"):
                // The error matches one of the expected cases, test passes
                break
            default:
                XCTFail("Error is not StreamError.notSupported with expected message")
            }
        }
    }

    private func addContentLengthMiddlewareWith(requiresLength: Bool?, unsignedPayload: Bool?) {
        stack.finalizeStep.intercept(
            position: .before,
            middleware: ContentLengthMiddleware(requiresLength: requiresLength, unsignedPayload: unsignedPayload)
        )
    }

    private func forceEmptyStream() {
        // Force stream length to be nil
        stack.finalizeStep.intercept(position: .before, id: "set nil stream length") { (context, input, next) -> OperationOutput<MockOutput> in
            input.body = .stream(BufferedStream()) // Set the stream length to nil
            return try await next.handle(context: context, input: input)
        }
    }
        
    private func AssertHeadersArePresent(expectedHeaders: [String: String], file: StaticString = #file, line: UInt = #line) async throws -> Void {
        let mockHandler = MockHandler { (_, input) in
            for (key, value) in expectedHeaders {
                XCTAssert(input.headers.value(for: key) == value, file: file, line: line)
            }
            let httpResponse = HttpResponse(body: ByteStream.noStream, statusCode: HttpStatusCode.ok)
            let mockOutput = try! await MockOutput(httpResponse: httpResponse, decoder: nil)
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse, output: mockOutput)
            return output
        }

        _ = try await stack.handleMiddleware(context: builtContext, input: MockInput(), next: mockHandler)
    }
}
