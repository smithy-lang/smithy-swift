// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

public struct ContentMD5Middleware<OperationStackOutput: HttpResponseBinding,
                                      OperationStackError: HttpResponseBinding>: Middleware {
    public let id: String = "ContentMD5"
    
    private let contentMD5HeaderName = "Content-MD5"
    
    public init() {}
    
    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) -> Result<MOutput, MError>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context,
    Self.MError == H.MiddlewareError {
        
        switch input.body {
        case .data(let data):
            guard let data = data else {
                return next.handle(context: context, input: input)
            }
            let md5base64 = MD5(data: data)
            input.headers.update(name: "Content-MD5", value: md5base64)
        case .stream(let stream):
            guard let logger = context.getLogger() else {
                return next.handle(context: context, input: input)
            }
            logger.error("TODO: Content-MD5 to stream buffer/reader")
        default:
            guard let logger = context.getLogger() else {
                return next.handle(context: context, input: input)
            }
            logger.error("Unhandled case for Content-MD5")
        }
        
        return next.handle(context: context, input: input)
    }

    // TODO: Investigate alternative implementation in AWS Common Runtime:
    //       https://github.com/awslabs/aws-sdk-swift/issues/379
    // Inspired from:
    // https://stackoverflow.com/questions/32163848/how-can-i-convert-a-string-to-an-md5-hash-in-ios-using-swift/32166735
    private func MD5(data messageData: Data) -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.base64EncodedString()
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
