//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import Smithy
import SmithyHTTPAPI
import protocol SmithySerialization.Codec
import protocol SmithySerialization.SerializableShape

@_spi(SmithyReadWrite)
public struct SchemaBodyMiddleware<OperationStackInput: SerializableShape> {
    public let id: Swift.String = "BodyMiddleware"
    let codec: any Codec

    public init(codec: any Codec) {
        self.codec = codec
    }
}

extension SchemaBodyMiddleware: RequestMessageSerializer {
    public typealias InputType = OperationStackInput
    public typealias RequestType = HTTPRequest

    public func apply(input: OperationStackInput, builder: HTTPRequestBuilder, attributes: Smithy.Context) throws {
        do {
            let serializer = try codec.makeSerializer()
            try input.serialize(serializer)
            let data = serializer.data
            let body = ByteStream.data(data)
            builder.withBody(body)
        } catch {
            throw ClientError.serializationFailed(error.localizedDescription)
        }
    }
}
