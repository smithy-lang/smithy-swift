// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import XCTest
import SmithyTestUtil
@testable import ClientRuntime

class FlexibleChecksumsRequestMiddlewareTests: XCTestCase {
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
                  .withLogger(value: SwiftLogger(label: "test"))
                  .build()
        stack = OperationStack<MockInput, MockOutput>(id: "Test Operation")
    }

    func testNormalPayloadSha256() async throws {
        let checksumAlgorithms = ["sha256"]
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithms: checksumAlgorithms)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-sha256",
            responseBody: testData,
            expectedChecksum: "MV9b23bQeMQ7isAGTkoBZGErH853yGk0W/yUx1iU7dM="
        )
    }
    
    func testNormalPayloadSha1() async throws {
        let checksumAlgorithms = ["sha1", "sha256"]
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithms: checksumAlgorithms)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-sha1",
            responseBody: testData,
            expectedChecksum: "lDpwLQbzRZmu4fjajvn3KWAx1pk="
        )
    }
    
    func testNormalPayloadCRC32() async throws {
        let checksumAlgorithms = ["crc32", "sha1", "sha256"]
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithms: checksumAlgorithms)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-crc32",
            responseBody: testData,
            expectedChecksum: "6+bG5g=="
        )
    }
    
    func testNormalPayloadCRC32C() async throws {
        let checksumAlgorithms = ["crc32c", "crc32", "sha1", "sha256"]
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithms: checksumAlgorithms)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-crc32c",
            responseBody: testData,
            expectedChecksum: "yKEG5Q=="
        )
    }
    
    func testNormalPayloadCRC32COutOfOrder() async throws {
        let checksumAlgorithms = ["crc32", "sha1", "sha256", "crc32c"]
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithms: checksumAlgorithms)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-crc32c",
            responseBody: testData,
            expectedChecksum: "yKEG5Q=="
        )
    }

    private func addFlexibleChecksumsRequestMiddleware(checksumAlgorithms: [String]) {
        stack.serializeStep.intercept(
            position: .after,
            middleware: FlexibleChecksumsRequestMiddleware<MockInput, MockOutput>(checksumAlgorithms: checksumAlgorithms)
        )
    }
    
    private func addFlexibleChecksumsResponseMiddleware(validationMode: Bool) {
        stack.deserializeStep.intercept(
            position: .after,
            middleware: FlexibleChecksumsResponseMiddleware<MockOutput>(validationMode: validationMode)
        )
    }
    
    private func setNormalPayload(payload: ByteStream) {
        // Set normal payload data
        stack.serializeStep.intercept(position: .before, id: "set normal payload") { (context, input, next) -> OperationOutput<MockOutput> in
            input.builder.body = payload // Set the payload data here
            return try await next.handle(context: context, input: input)
        }
    }
    
    private func AssertHeaderIsPresentAndValidationOccurs(
        expectedHeader: String,
        responseBody: ByteStream,
        expectedChecksum: String
    ) async throws -> Void {
        let file: StaticString = #file
        let line: UInt = #line
        var isChecksumValidated = false
        let mockHandler = MockHandler { (_, input) in
            XCTAssert(input.headers.value(for: expectedHeader) != nil, file: file, line: line)
            let httpResponse = HttpResponse(body: responseBody, statusCode: HttpStatusCode.ok)
            httpResponse.headers.add(name: expectedHeader, value: expectedChecksum)
            let mockOutput = try! MockOutput(httpResponse: httpResponse, decoder: nil)
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse, output: mockOutput)
            if let validatedChecksum = self.builtContext.attributes.get(key: AttributeKey<String>(name: "ChecksumHeaderValidated")), validatedChecksum == expectedHeader {
                isChecksumValidated = true
            }
            return output
        }

        _ = try await stack.handleMiddleware(context: builtContext, input: MockInput(), next: mockHandler)
        
        // Assert that the expected checksum was validated
        XCTAssertTrue(isChecksumValidated, "Checksum was not validated as expected.")
    }
}
