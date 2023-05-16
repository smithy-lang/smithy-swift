//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import ClientRuntime
import SmithyTestUtil

class OperationStackTests: HttpRequestTestBase {

    #if swift(>=5.7) && !os(Linux)
    func testMiddlewareInjectableInit() async throws {
        var currExpectCount = 1
        let defaultTimeout = 2.0
        let expectInitializeMiddleware = expectation(description: "initializeMiddleware")
        let expectSerializeMiddleware = expectation(description: "serializeMiddleware")
        let expectBuildMiddleware = expectation(description: "buildMiddleware")
        let expectFinalizeMiddleware = expectation(description: "finalizeMiddlware")
        let expectDeserializeMiddleware = expectation(description: "deserializeMiddleware")
        let expectHandler = expectation(description: "handler")

        let addContextValues = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
        let builtContext = addContextValues.build()

        var stack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "Test Operation")
        stack.initializeStep.intercept(position: .before, middleware: MockInitializeMiddleware(id: "TestInitializeMiddleware", callback: { _, _ in
            currExpectCount = self.checkAndFulfill(currExpectCount, 1, expectation: expectInitializeMiddleware)
        }))

        stack.serializeStep.intercept(position: .before, middleware: MockSerializeMiddleware(
                                        id: "TestSerializeMiddleware",
                                        headerName: "TestHeaderName1",
                                        headerValue: "TestHeaderValue1",
                                        callback: { _, _ in
                                            currExpectCount = self.checkAndFulfill(currExpectCount, 2, expectation: expectSerializeMiddleware)
                                        }))

        stack.buildStep.intercept(position: .before, middleware: MockBuildMiddleware(id: "TestBuildMiddleware", callback: { _, _ in
            currExpectCount = self.checkAndFulfill(currExpectCount, 3, expectation: expectBuildMiddleware)
        }))

        stack.finalizeStep.intercept(position: .before, middleware: MockFinalizeMiddleware(id: "TestFinalizeMiddleware", callback: { _, _ in
            currExpectCount = self.checkAndFulfill(currExpectCount, 4, expectation: expectFinalizeMiddleware)
        }))

        stack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                            id: "TestDeserializeMiddleware",
                                            callback: {_, _ in
                                                currExpectCount = self.checkAndFulfill(currExpectCount, 5, expectation: expectDeserializeMiddleware)
                                                return nil
                                            }))

        let result = try await stack.handleMiddleware(context: builtContext,
                                            input: MockInput(),
                                            next: MockHandler { (_, request) in
                                                currExpectCount = self.checkAndFulfill(currExpectCount, 6, expectation: expectHandler)
                                                XCTAssert(request.headers.value(for: "TestHeaderName1") == "TestHeaderValue1")
                                                let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
                                                let output = OperationOutput<MockOutput>(httpResponse: httpResponse)
                                                return output
                                            })
        await fulfillment(of: [expectInitializeMiddleware,
                   expectSerializeMiddleware,
                   expectBuildMiddleware,
                   expectFinalizeMiddleware,
                   expectDeserializeMiddleware,
                   expectHandler],
             timeout: defaultTimeout)
        XCTAssert(result.value == 200)
    }
    #endif

    private func checkAndFulfill(_ currCount: Int, _ expectedCount: Int, expectation: XCTestExpectation) -> Int {
        if currCount == expectedCount {
            expectation.fulfill()
            return currCount + 1
        }
        return currCount
    }
}
