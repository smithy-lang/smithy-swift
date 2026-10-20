//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import Smithy
import SmithyHTTPAPI
@_spi(SmithyReadWrite) import protocol SmithyReadWrite.SmithyWriter
@_spi(SmithyReadWrite) import typealias SmithyReadWrite.WritingClosure

@_spi(SmithyReadWrite)
public struct BodyMiddleware<OperationStackInput,
                             OperationStackOutput,
                             Writer: SmithyWriter> {
    public let id: Swift.String = "BodyMiddleware"

    let rootNodeInfo: Writer.NodeInfo
    let inputWritingClosure: WritingClosure<OperationStackInput, Writer>

    public init(
        rootNodeInfo: Writer.NodeInfo,
        inputWritingClosure: @escaping WritingClosure<OperationStackInput, Writer>
    ) {
        self.rootNodeInfo = rootNodeInfo
        self.inputWritingClosure = inputWritingClosure
    }
}

extension BodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        do {
            let data = try Writer.write(
                input,
                rootNodeInfo: rootNodeInfo,
                with: inputWritingClosure
            )
            let body = ByteStream.data(data)
            builder.withBody(body)
        } catch {
            throw ClientError.serializationFailed(error.localizedDescription)
        }
    }
}
