//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import ClientRuntime
import SmithyHTTPAPI

class SerializationBenchmarkInterceptor<InputType, OutputType>: Interceptor {
    typealias RequestType = HTTPRequest
    typealias ResponseType = HTTPResponse

    let serializationTime: BoxedDouble

    public init(
        _ serializationTime: BoxedDouble
    ) {
        self.serializationTime = serializationTime
    }

    func readAfterSerialization(context: some AfterSerialization<InputType, RequestType>) async throws {
        let serializeDuration = context.getAttributes().get(key: AttributeKey<Double>(name: "SerializeDuration"))
        serializationTime.value = serializeDuration ?? 0
    }
}

class SerializationBenchmarkInterceptorProvider: HttpInterceptorProvider {
    let serializationTime: BoxedDouble

    public init(
        _ serializationTime: BoxedDouble
    ) {
        self.serializationTime = serializationTime
    }
  func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
    return SerializationBenchmarkInterceptor(serializationTime)
  }
}
