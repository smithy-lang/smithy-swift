//
//  StreamingProvider.swift
//
//  Created by Stone, Nicki on 5/29/20.
//  Copyright © 2020 Stone, Nicki. All rights reserved.
//

import AwsCommonRuntimeKit
import struct Foundation.Data

public class StreamSource {
    public typealias StreamClosure = (StreamStatus, ByteBuffer?, StreamErrors?) -> Void
    var byteBuffer: ByteBuffer

    var streamResponse: StreamClosure?
    
    init(byteBuffer: ByteBuffer) {
        self.byteBuffer = byteBuffer
    }
    
    public convenience init(data: Data) {
        let byteBuffer = ByteBuffer(data: data)
        self.init(byteBuffer: byteBuffer)
    }

    public func stream(closure: @escaping StreamClosure) {
        streamResponse = closure
    }
    
    public func toData() -> Data {
        return byteBuffer.toData()
    }
}
