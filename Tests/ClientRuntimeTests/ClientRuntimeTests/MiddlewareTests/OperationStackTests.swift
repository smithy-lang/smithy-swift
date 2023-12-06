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

    func testMiddlewareInjectableInit() async throws {
        var currExpectCount = 1

        let addContextValues = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
        let builtContext = addContextValues.build()

        var stack = OperationStack<MockInput, MockOutput>(id: "Test Operation")
        stack.initializeStep.intercept(position: .before, middleware: MockInitializeMiddleware(id: "TestInitializeMiddleware", callback: { _, _ in
            self.checkOrder(&currExpectCount, 1)
        }))

        stack.serializeStep.intercept(position: .before, middleware: MockSerializeMiddleware(
                                        id: "TestSerializeMiddleware",
                                        headerName: "TestHeaderName1",
                                        headerValue: "TestHeaderValue1",
                                        callback: { _, _ in
                                            self.checkOrder(&currExpectCount, 2)
                                        }))

        stack.buildStep.intercept(position: .before, middleware: MockBuildMiddleware(id: "TestBuildMiddleware", callback: { _, _ in
            self.checkOrder(&currExpectCount, 3)
        }))

        stack.finalizeStep.intercept(position: .before, middleware: MockFinalizeMiddleware(id: "TestFinalizeMiddleware", callback: { _, _ in
            self.checkOrder(&currExpectCount, 4)
        }))

        stack.deserializeStep.intercept(position: .after, middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                                            id: "TestDeserializeMiddleware",
                                            callback: {_, _ in
                                                self.checkOrder(&currExpectCount, 5)
                                                return nil
                                            }))

        let result = try await stack.handleMiddleware(context: builtContext,
                                            input: MockInput(),
                                            next: MockHandler { (_, request) in
                                                self.checkOrder(&currExpectCount, 6)
                                                XCTAssert(request.headers.value(for: "TestHeaderName1") == "TestHeaderValue1")
                                                let httpResponse = HttpResponse(body: ByteStream.none, statusCode: HttpStatusCode.ok)
                                                let output = OperationOutput<MockOutput>(httpResponse: httpResponse)
                                                return output
                                            })
        XCTAssertEqual(result.value, 200)
        XCTAssertEqual(currExpectCount, 7)
    }

    private func checkOrder(_ currCount: inout Int, _ expectedCount: Int) {
        if currCount == expectedCount {
            currCount += 1
        } else {
            XCTFail("Expected count: \(expectedCount) actual count: \(currCount)")
        }
    }
}
