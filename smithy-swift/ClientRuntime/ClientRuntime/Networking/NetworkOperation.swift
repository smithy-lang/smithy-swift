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

import Foundation

open class NetworkOperation: Operation {

    public var task: URLSessionTask?
    //creation of empty http response to be filled out by delegate calls
    public var response: HttpResponse?

    public var error: Error?

    public var completion: NetworkResult?

    enum OperationState: Int {
        case ready
        case executing
        case finished
    }

    // def   completion(Result.success(response))ault state is ready (when the operation is created)
    internal var state: OperationState = .ready {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
            self.willChangeValue(forKey: "isFinished")
        }

        didSet {
            self.didChangeValue(forKey: "isExecuting")
            self.didChangeValue(forKey: "isFinished")
        }
    }

    open override var isReady: Bool { return state == .ready }
    open override var isExecuting: Bool { return state == .executing }
    open override var isFinished: Bool { return state == .finished }

    open override func start() {
        /*
         if the operation or queue got cancelled even
         before the operation has started, set the
         operation state to finished and return
         */
        if self.isCancelled {
            state = .finished
            return
        }

        // set the state to executing
        state = .executing

        // start the task
        self.task?.resume()
    }

    open override func cancel() {
        super.cancel()

        // cancel the task
        self.task?.cancel()
    }

    open func receiveData(data: Data) {
        //subclasses must implement on how they want to receive data
        fatalError()
    }

    open func receiveResponse(urlResponse: URLResponse) {
        response = HttpResponse(httpUrlResponse: urlResponse as! HTTPURLResponse, content: nil)
    }

    open func receiveError(error: Error) {
        completion?(.failure(error))
        self.state = .finished
    }

    open func finish(error: Error? = nil) {

        if let error = error {
            completion?(.failure(error))
        } else {
            completion?(.success(response!))
        }

        self.state = .finished
    }

}
