// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import Smithy
import SmithyHTTPAPI
import XCTest
import SmithyTestUtil
@testable import ClientRuntime
import class SmithyStreams.BufferedStream

class ContentLengthMiddlewareTests: XCTestCase {
    private var builtContext: Context!
    private var builder: OrchestratorBuilder<MockInput, MockOutput, SdkHttpRequest, HttpResponse>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        builtContext = ContextBuilder()
                  .withMethod(value: .get)
                  .withPath(value: "/")
                  .withOperation(value: "Test Operation")
                  .build()
        builder = TestOrchestrator.httpBuilder()
            .attributes(builtContext)
            .serialize(MockSerializeMiddleware(id: "TestMiddleware", headerName: "TestName", headerValue: "TestValue"))
            .deserialize(MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: MockOutput.responseClosure(_:)))
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
        builder.interceptors.add(ContentLengthMiddleware<MockInput, MockOutput>(requiresLength: requiresLength, unsignedPayload: unsignedPayload))
    }

    private func forceEmptyStream() {
        // Force stream length to be nil
        builder.interceptors.addModifyBeforeSigning({ ctx in
            ctx.updateRequest(updated: ctx.getRequest().toBuilder()
                .withBody(.stream(BufferedStream()))
                .build())
        })
    }

    private func AssertHeadersArePresent(expectedHeaders: [String: String], file: StaticString = #file, line: UInt = #line) async throws -> Void {
        builder.executeRequest({ req, ctx in
            for (key, value) in expectedHeaders {
                XCTAssert(req.headers.value(for: key) == value, file: file, line: line)
            }
            return HttpResponse(body: .noStream, statusCode: .ok)
        })
        _ = try await builder.build().execute(input: MockInput())
    }
}
