//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import ClientRuntime
import SmithyHTTPAPI

public class SerializationBenchmarkInterceptor<InputType, OutputType>: Interceptor {
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public let serializationTime: BoxedDouble

    public init(
        _ serializationTime: BoxedDouble
    ) {
        self.serializationTime = serializationTime
    }

    public func readAfterSerialization(context: some AfterSerialization<InputType, RequestType>) async throws {
        let serializeDuration = context.getAttributes().get(key: AttributeKey<Double>(name: "SerializeDuration"))
        serializationTime.value = serializeDuration ?? 0
    }
}

public class SerializationBenchmarkInterceptorProvider: HttpInterceptorProvider {
    public let serializationTime: BoxedDouble

    public init(
        _ serializationTime: BoxedDouble
    ) {
        self.serializationTime = serializationTime
    }

    public func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
        return SerializationBenchmarkInterceptor(serializationTime)
    }
}
