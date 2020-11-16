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
import AwsCommonRuntimeKit

// we need to maintain a reference to this same request while we add headers in the CRT engine so that is why it's a class
public class SdkHttpRequest {
    public var body: HttpBody?
    public var headers: Headers
    public let queryItems: [URLQueryItem]?
    public let endpoint: Endpoint
    public let method: HttpMethodType
    
    public init(method: HttpMethodType,
                endpoint: Endpoint,
                headers: Headers,
                queryItems: [URLQueryItem]? = nil,
                body: HttpBody? = nil) {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.body = body
        self.queryItems = queryItems
    }
}

extension SdkHttpRequest {
    public func toHttpRequest() throws -> HttpRequest {
        let httpHeaders = headers.toHttpHeaders()
        let httpRequest = HttpRequest(headers: httpHeaders)
        httpRequest.method = method.rawValue
        httpRequest.path = endpoint.path
      
        var awsInputStream: AwsInputStream?
        switch body {
        case .data(let data):
            if let data = data {
                let byteBuffer = ByteBuffer(size: data.count)
                let byteBufferWithData = byteBuffer.put(data)
                awsInputStream = AwsInputStream(byteBufferWithData)
            }
        case .file(let url):
            do {
                let fileHandle = try FileHandle(forReadingFrom: url)
                awsInputStream = AwsInputStream(fileHandle)
            } catch let err {
                throw ClientError.serializationFailed("Opening the file handle failed. Check path to file. Error: " + err.localizedDescription)
            }
        case .stream(let stream):
            //TODO: refactor ability to stream appropriately and get buffer capacity here
            do {
                let data = try stream?.readData(maxLength: 1024)
                if let data = data {
                    let byteBuffer = ByteBuffer(size: data.count)
                    let byteBufferWithData = byteBuffer.put(data)
                    awsInputStream = AwsInputStream(byteBufferWithData)
                }
            } catch let err {
                throw ClientError.serializationFailed("Reading from stream failed: " + err.localizedDescription)
            }
        case .none:
            break //do nothing as inputstream is already nil
        }
        if let inputStream = awsInputStream {
            httpRequest.body = inputStream
        }
        
        return httpRequest
    }
}
