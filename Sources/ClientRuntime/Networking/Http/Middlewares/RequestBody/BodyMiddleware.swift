//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import struct Foundation.Data
@_spi(SmithyReadWrite) import protocol SmithyReadWrite.SmithyWriter
@_spi(SmithyReadWrite) import typealias SmithyReadWrite.WritingClosure

@_spi(SmithyReadWrite)
public struct BodyMiddleware<OperationStackInput,
                             OperationStackOutput,
                             Writer: SmithyWriter> {
    public let id: Swift.String = "BodyMiddleware"

    let rootNodeInfo: Writer.NodeInfo
    let inputWritingClosure: WritingClosure<OperationStackInput, Writer>
    let operationName: String

    public init(
        rootNodeInfo: Writer.NodeInfo,
        inputWritingClosure: @escaping WritingClosure<OperationStackInput, Writer>,
        _ operationName: String = "Unsupported"
    ) {
        self.rootNodeInfo = rootNodeInfo
        self.inputWritingClosure = inputWritingClosure
        self.operationName = operationName
    }
}

extension BodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput

    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        do {
            let serializationStart = Date().timeIntervalSince1970

            let data = try Writer.write(
                input,
                rootNodeInfo: rootNodeInfo,
                with: inputWritingClosure
            )

            let serializationEnd = Date().timeIntervalSince1970
            let serializationElapsedMs = (serializationEnd - serializationStart) * 1000.0  // in milliseconds

            SerializationMetrics.shared.record(time: serializationElapsedMs, for: operationName)

            let body = ByteStream.data(data)
            builder.withBody(body)
        } catch {
            throw ClientError.serializationFailed(error.localizedDescription)
        }
    }
}
