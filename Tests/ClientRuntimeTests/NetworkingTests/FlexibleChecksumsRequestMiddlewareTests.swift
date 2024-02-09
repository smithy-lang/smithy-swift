// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import XCTest
import AwsCommonRuntimeKit
import SmithyTestUtil
@testable import ClientRuntime

class FlexibleChecksumsRequestMiddlewareTests: XCTestCase {
    private var builtContext: HttpContext!
    private var stack: OperationStack<MockInput, MockOutput>!
    private let testLogger = TestLogger()

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Initialize function needs to be called before interacting with CRT
        CommonRuntimeKit.initialize()

        builtContext = HttpContextBuilder()
                  .withMethod(value: .get)
                  .withPath(value: "/")
                  .withEncoder(value: JSONEncoder())
                  .withDecoder(value: JSONDecoder())
                  .withOperation(value: "Test Operation")
                  .withLogger(value: testLogger)
                  .build()
        stack = OperationStack<MockInput, MockOutput>(id: "Test Operation")
    }

    func testNormalPayloadSha256() async throws {
        let checksumAlgorithm = "sha256"
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithm: checksumAlgorithm)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-sha256",
            responseBody: testData,
            expectedChecksum: "MV9b23bQeMQ7isAGTkoBZGErH853yGk0W/yUx1iU7dM="
        )
    }
    
    func testNormalPayloadSha1() async throws {
        let checksumAlgorithm = "sha1"
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithm: checksumAlgorithm)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-sha1",
            responseBody: testData,
            expectedChecksum: "lDpwLQbzRZmu4fjajvn3KWAx1pk="
        )
    }
    
    func testNormalPayloadCRC32() async throws {
        let checksumAlgorithm = "crc32"
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithm: checksumAlgorithm)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-crc32",
            responseBody: testData,
            expectedChecksum: "6+bG5g=="
        )
    }
    
    func testNormalPayloadCRC32C() async throws {
        let checksumAlgorithm = "crc32c"
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithm: checksumAlgorithm)
        addFlexibleChecksumsResponseMiddleware(validationMode: true)
        try await AssertHeaderIsPresentAndValidationOccurs(
            expectedHeader: "x-amz-checksum-crc32c",
            responseBody: testData,
            expectedChecksum: "yKEG5Q=="
        )
    }
    
    func testNilChecksumAlgorithm() async throws {
        let testData = ByteStream.data(Data("Hello, world!".utf8))
        setNormalPayload(
            payload: testData
        )
        addFlexibleChecksumsRequestMiddleware(checksumAlgorithm: nil)
        addFlexibleChecksumsResponseMiddleware(validationMode: false)
        try await AssertHeaderIsPresentAndValidationOccurs(
            checkLogs: [
                "No checksum provided! Skipping flexible checksums workflow...",
                "Checksum validation should not be performed! Skipping workflow..."
            ]
        )
    }

    private func addFlexibleChecksumsRequestMiddleware(checksumAlgorithm: String?) {
        stack.serializeStep.intercept(
            position: .after,
            middleware: FlexibleChecksumsRequestMiddleware<MockInput, MockOutput>(checksumAlgorithm: checksumAlgorithm)
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
        expectedHeader: String = "",
        responseBody: ByteStream = ByteStream.noStream,
        expectedChecksum: String = "",
        checkLogs: [String] = []
    ) async throws -> Void {
        let file: StaticString = #file
        let line: UInt = #line
        var isChecksumValidated = false
        let mockHandler = MockHandler { (_, input) in
            if expectedHeader != "" {
                XCTAssert(input.headers.value(for: expectedHeader) != nil, file: file, line: line)
            }
            let httpResponse = HttpResponse(body: responseBody, statusCode: HttpStatusCode.ok)
            await httpResponse.addHeaders(
                additionalHeaders: Headers([expectedHeader: expectedChecksum])
            )
            let mockOutput = try! await MockOutput(httpResponse: httpResponse, decoder: nil)
            let output = OperationOutput<MockOutput>(httpResponse: httpResponse, output: mockOutput)
            if let validatedChecksum = self.builtContext.attributes.get(key: AttributeKey<String>(name: "ChecksumHeaderValidated")), validatedChecksum == expectedHeader {
                isChecksumValidated = true
            }
            return output
        }

        _ = try await stack.handleMiddleware(context: builtContext, input: MockInput(), next: mockHandler)
        
        if !checkLogs.isEmpty {
            checkLogs.forEach { expectedLog in
                XCTAssertTrue(testLogger.messages.contains { $0.level == .info && $0.message.contains(expectedLog) }, "Expected log message not found")
            }
        }

        if expectedChecksum != "" {
            // Assert that the expected checksum was validated
            XCTAssertTrue(isChecksumValidated, "Checksum was not validated as expected.")
        }
    }
}

class TestLogger: LogAgent {
    var name: String

    var messages: [(level: LogAgentLevel, message: String)] = []

    var level: ClientRuntime.LogAgentLevel

    init(name: String = "Test", messages: [(level: LogAgentLevel, message: String)] = [], level: ClientRuntime.LogAgentLevel = .info) {
        self.name = name
        self.messages = messages
        self.level = level
    }

    func log(level: ClientRuntime.LogAgentLevel = .info, message: String, metadata: [String : String]? = nil, source: String = "ChecksumUnitTests", file: String = #file, function: String = #function, line: UInt = #line) {
        messages.append((level: level, message: message))
    }
}
