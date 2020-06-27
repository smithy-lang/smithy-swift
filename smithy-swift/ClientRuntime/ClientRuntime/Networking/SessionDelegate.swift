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

class SessionDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

    let operationQueue: OperationQueue

    init(operationQueue: OperationQueue) {
        self.operationQueue = operationQueue
        super.init()
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        //session suddenly became invalid, cancel everything in progress
        self.operationQueue.cancelAllOperations()
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        print("did send body data")
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        print("became a stream task")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        print("did finish collecting metrics")
        print(metrics)
    }

    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        print("task is waitin for connectivity")
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("received data")
        let operation = self.operationQueue.networkOperations.first(where: {$0.task == dataTask})
        operation?.receiveData(data: data)
    }

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("did receive url response")
        let operation = self.operationQueue.networkOperations.first(where: {$0.task == dataTask})
        operation?.receiveResponse(urlResponse: response)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("did complete")
        CFRunLoopStop(CFRunLoopGetCurrent())
        let operation = self.operationQueue.networkOperations.first(where: {$0.task == task})
        guard let error = error else {
            //completed with error but error is nil? what to do here
            operation?.finish(error: nil)
           return
        }
        operation?.receiveError(error: error)

    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        print("stream is about to send")
        let operation = self.operationQueue.networkOperations.first(where: {$0.task == task})
        let streamingOperation = operation as! StreamingNetworkOperation
        completionHandler(streamingOperation.streamingProvider?.boundStreams.input)
        CFRunLoopRun()
    }
}
