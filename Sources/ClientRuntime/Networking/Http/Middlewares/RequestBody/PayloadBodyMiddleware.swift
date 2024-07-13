//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ByteStream
import enum Smithy.ClientError
import protocol Smithy.RequestMessageSerializer
import class Smithy.Context
import struct Foundation.Data
import protocol SmithyReadWrite.SmithyWriter
import typealias SmithyReadWrite.WritingClosure
import SmithyHTTPAPI

public struct PayloadBodyMiddleware<OperationStackInput,
                                    OperationStackOutput,
                                    OperationStackInputPayload,
                                    Writer: SmithyWriter> {
    public let id: Swift.String = "PayloadBodyMiddleware"

    let rootNodeInfo: Writer.NodeInfo
    let inputWritingClosure: WritingClosure<OperationStackInputPayload, Writer>
    let keyPath: KeyPath<OperationStackInput, OperationStackInputPayload?>
    let defaultBody: String?

    public init(
        rootNodeInfo: Writer.NodeInfo,
        inputWritingClosure: @escaping WritingClosure<OperationStackInputPayload, Writer>,
        keyPath: KeyPath<OperationStackInput, OperationStackInputPayload?>,
        defaultBody: String?
    ) {
        self.rootNodeInfo = rootNodeInfo
        self.inputWritingClosure = inputWritingClosure
        self.keyPath = keyPath
        self.defaultBody = defaultBody
    }
}

extension PayloadBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        do {
            if let payload = input[keyPath: keyPath] {
                let data = try Writer.write(
                    payload,
                    rootNodeInfo: rootNodeInfo,
                    with: inputWritingClosure
                )
                let body = ByteStream.data(data)
                builder.withBody(body)
            } else if let defaultBody {
                builder.withBody(.data(Data(defaultBody.utf8)))
            }
        } catch {
            throw ClientError.serializationFailed(error.localizedDescription)
        }
    }
}
