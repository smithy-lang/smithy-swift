//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import ClientRuntime
import SmithyTestUtil

class OperationStackTests : HttpRequestTestBase {
    
    func testMiddlewareInjectableInit() {
        var currExpectCount = 1
        let defaultTimeout = 2.0
        let expectInitialize = expectation(description: "initialize")
        let expectSerialize = expectation(description: "serialize")
        let expectSerializeMiddleware = expectation(description: "serialize")
        let expectBuild = expectation(description: "build")
        let expectFinalize = expectation(description: "finalize")
        let expectDeserialize = expectation(description: "deserialize")
        let expectDeserializeMiddleware = expectation(description: "deserializeMiddleware")
        let expectHandler = expectation(description: "handler")

        let addContextValues = HttpContextBuilder()
            .withMethod(value: .get)
            .withPath(value: "/")
            .withEncoder(value: JSONEncoder())
            .withDecoder(value: JSONDecoder())
            .withOperation(value: "Test Operation")
        let builtContext = addContextValues.build()
        let mockInitializeStackStep: MockInitializeStackStep<MockInput> = constructMockInitializeStackStep(){ context, input in
            currExpectCount = self.checkAndFulfill(currExpectCount, 1, expectation: expectInitialize)
            return .success("not used")
        }
        let mockSerializeStackStep: MockSerializeStackStep<MockInput>
            = constructMockSerializeStackStep(){ context, input in
            currExpectCount = self.checkAndFulfill(currExpectCount, 2, expectation: expectSerialize)
            return .success("not used")
        } interceptCallback: {
            var step = SerializeStep<MockInput>()
            step.intercept(position: .before,
                           middleware: MockSerializeMiddleware(
                            id: "TestSerializeMiddleware",
                            headerName: "TestHeaderName1",
                            headerValue: "TestHeaderValue1",
                            callback: { _,_ in
                                currExpectCount = self.checkAndFulfill(currExpectCount, 3, expectation: expectSerializeMiddleware)
                            }))
            return step
        }
        let mockBuildStackStep: MockBuildStackStep<MockInput> = constructMockBuildStackStep(){ context, input in
            currExpectCount = self.checkAndFulfill(currExpectCount, 4, expectation: expectBuild)
            return .success("not used")
        }
        let mockFinalizeStackStep = constructMockFinalizeStackStep(){ context, input in
            currExpectCount = self.checkAndFulfill(currExpectCount, 5, expectation: expectFinalize)
            return .success("not used")
        }
        let mockDeserializeStackStep: MockDeserializeStackStep<MockOutput, MockMiddlewareError>
            = constructMockDeserializeStackStep(){ context, input in
            currExpectCount = self.checkAndFulfill(currExpectCount, 6, expectation: expectDeserialize)
            return .success("not used")
        } interceptCallback: {
            var step = DeserializeStep<MockOutput, MockMiddlewareError>()
            step.intercept(position: .after,
                           middleware: MockDeserializeMiddleware<MockOutput, MockMiddlewareError>(
                            id: "TestDeserializeMiddleware",
                            callback: {_,_ in
                                currExpectCount = self.checkAndFulfill(currExpectCount, 7, expectation: expectDeserializeMiddleware)
                                return nil
                            }))
            return step
        }
        let stack = OperationStack<MockInput, MockOutput, MockMiddlewareError>(id: "Test Operation",
                                                                               initializeStackStep: mockInitializeStackStep,
                                                                               serializeStackStep: mockSerializeStackStep,
                                                                               buildStackStep: mockBuildStackStep,
                                                                               finalizeStackStep: mockFinalizeStackStep,
                                                                               deserializeStackStep: mockDeserializeStackStep)

        let result = stack.handleMiddleware(context: builtContext,
                                            input: MockInput(),
                                            next:MockHandler(){ (context, request) in
                                                currExpectCount = self.checkAndFulfill(currExpectCount, 8, expectation: expectHandler)
                                                XCTAssert(request.headers.value(for: "TestHeaderName1") == "TestHeaderValue1")
                                                let httpResponse = HttpResponse(body: HttpBody.none, statusCode: HttpStatusCode.ok)
                                                let output = DeserializeOutput<MockOutput, MockMiddlewareError>(httpResponse: httpResponse)
                                                return .success(output)
                                            })

        wait(for: [expectInitialize,
                   expectSerialize,
                   expectSerializeMiddleware,
                   expectBuild,
                   expectFinalize,
                   expectDeserialize,
                   expectDeserializeMiddleware,
                   expectHandler],
             timeout: defaultTimeout)
        
        switch result {
        case .success(let output):
            XCTAssert(output.value == 200)
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }

    private func checkAndFulfill(_ currCount: Int, _ expectedCount: Int, expectation: XCTestExpectation) -> Int {
        if currCount == expectedCount {
            expectation.fulfill()
            return currCount + 1
        }
        return currCount
    }
}
    
