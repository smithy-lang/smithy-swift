//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import ClientRuntime
import SmithyHTTPAPI

public class DeserializationBenchmarkInterceptor<InputType, OutputType>: Interceptor {
    public typealias RequestType = HTTPRequest
    public typealias ResponseType = HTTPResponse

    public let deserializationTime: BoxedDouble

    public init(
        _ deserializationTime: BoxedDouble
    ) {
        self.deserializationTime = deserializationTime
    }

    public func readAfterDeserialization(
        context: some AfterDeserialization<InputType, OutputType, RequestType, ResponseType>
    ) async throws {
        let deserializeDuration = context.getAttributes().get(key: AttributeKey<Double>(name: "DeserializeDuration"))
        deserializationTime.value = deserializeDuration ?? 0
    }
}

public class DeserializationBenchmarkInterceptorProvider: HttpInterceptorProvider {
    public let deserializationTime: BoxedDouble

    public init(
        _ deserializationTime: BoxedDouble
    ) {
        self.deserializationTime = deserializationTime
    }

    public func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
        return DeserializationBenchmarkInterceptor(deserializationTime)
    }
}
