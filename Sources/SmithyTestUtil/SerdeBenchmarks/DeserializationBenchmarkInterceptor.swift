//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import ClientRuntime
import SmithyHTTPAPI

class DeserializationBenchmarkInterceptor<InputType, OutputType>: Interceptor {
    typealias RequestType = HTTPRequest
    typealias ResponseType = HTTPResponse
    
    let deserializationTime: BoxedDouble
    
    public init(
        _ deserializationTime: BoxedDouble
    ) {
        self.deserializationTime = deserializationTime
    }
    
    func readAfterDeserialization(
        context: some AfterDeserialization<InputType, OutputType, RequestType, ResponseType>
    ) async throws {
        let deserializeDuration = context.getAttributes().get(key: AttributeKey<Double>(name: "DeserializeDuration"))
        deserializationTime.value = deserializeDuration ?? 0
    }
}

class DeserializationBenchmarkInterceptorProvider: HttpInterceptorProvider {
    let deserializationTime: BoxedDouble
    
    public init(
        _ deserializationTime: BoxedDouble
    ) {
        self.deserializationTime = deserializationTime
    }
    func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
        return DeserializationBenchmarkInterceptor(deserializationTime)
    }
}
