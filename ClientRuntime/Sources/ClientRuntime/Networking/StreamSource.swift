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

import AwsCommonRuntimeKit
import struct Foundation.Data

public class StreamSource {
    public typealias StreamClosure = (StreamStatus, ByteBuffer?, StreamError?) -> Void
    var inputByteBuffer: ByteBuffer?
    var outputByteBuffer: ByteBuffer?
    var bufferSize: Int64
    
    var streamStatus: StreamStatus
    
    var streamResponse: StreamClosure?
    
    init(inputByteBuffer: ByteBuffer) {
        self.inputByteBuffer = inputByteBuffer
        self.bufferSize = inputByteBuffer.length
        self.streamStatus = .notAvailable
    }
    
    public convenience init(data: Data) {
        let byteBuffer = ByteBuffer(data: data)
        self.init(inputByteBuffer: byteBuffer)
    }
    
    public func stream(closure: @escaping StreamClosure) {
        streamResponse = closure
    }
    
    public func toData() -> Data? {
        return outputByteBuffer?.toData()
    }
    
    func receiveData(streamStatus: StreamStatus, byteBuffer: ByteBuffer, error: StreamError?) {
        if let streamResponse = streamResponse {
            streamResponse(streamStatus, byteBuffer, error)
        }
    }
}
