//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import XCTest
@testable import ClientRuntime

class HttpClientTests: NetworkingTestUtils {

    var httpClient: HttpClient!
    let mockSession = MockURLSession()

    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration(operationQueue: mockOperationQueue)
        httpClient = HttpClient(session: mockSession, config: httpClientConfiguration)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDataTaskIsCreatedWithCorrectURL() {
        _ = httpClient.execute(request: mockHttpDataRequest) { _ in }

        XCTAssert(mockSession.lastURL == expectedMockRequestURL)
    }

    func testSuppliedOperationQueueIsUsed() {
        XCTAssertEqual(httpClient.operationQueue.name, mockOperationQueue.name)
    }

    func testDataNetworkOperationIsAddedToOperationQueue() {
        // Assert that operation queue is intially empty
        XCTAssertEqual(httpClient.operationQueue.operationCount, 0)

        _ = httpClient.execute(request: mockHttpDataRequest) { _ in }

        // Assert that only a single DataNetworkOperation is added to operation queue
        XCTAssertEqual(httpClient.operationQueue.operationCount, 1)

        XCTAssertTrue(httpClient.operationQueue.operations.first is DataNetworkOperation)
    }

    func testCorrectDataTaskIsAddedToNetworkOperation() {
        // Assert that operation queue is intially empty
        XCTAssertEqual(httpClient.operationQueue.operationCount, 0)

        _ = httpClient.execute(request: mockHttpDataRequest) { _ in }

        let addedDataNetworkOperation = httpClient.operationQueue.operations.first as! DataNetworkOperation
        XCTAssertTrue(addedDataNetworkOperation.task is MockURLSessionDataTask)
    }

    func testNetworkOperationIsCancellable() {
        // Assert that operation queue is intially empty
        XCTAssertEqual(httpClient.operationQueue.operationCount, 0)

        _ = httpClient.execute(request: mockHttpDataRequest) { _ in }

        let addedDataNetworkOperation = httpClient.operationQueue.operations.first as! NetworkOperation

        XCTAssertNoThrow(addedDataNetworkOperation.cancel())
        XCTAssertTrue(addedDataNetworkOperation.isCancelled)

        // Assert cancelling an operation cancels the underlying data network task
        let mockDataTaskInDataNetworkOperation = addedDataNetworkOperation.task as! MockURLSessionDataTask

        XCTAssertTrue(mockDataTaskInDataNetworkOperation.cancelWasCalled)

        // Assert starting a cancelled operation sets the state to finished without resuming the underlying data network task
        addedDataNetworkOperation.start()
        XCTAssertTrue(addedDataNetworkOperation.isFinished)
    }

}
