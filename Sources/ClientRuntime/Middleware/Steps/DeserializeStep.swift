//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.HttpResponse

/// Reacts to the handler's response returned by the recipient of the request
/// message. Deserializes the response into a structured type or error above
/// stacks can react to.
///
/// Should only forward Request to underlying handler.
///
/// Takes Request, and returns result or error.
///
/// Receives raw response, or error from underlying handler.
public typealias DeserializeStep<OperationStackOutput> = MiddlewareStep<SdkHttpRequest,
                                                                        OperationOutput<OperationStackOutput>>

public let DeserializeStepId = "Deserialize"

public struct DeserializeStepHandler<OperationStackOutput, H: Handler>: Handler
    where H.Input == SdkHttpRequest,
          H.Output == OperationOutput<OperationStackOutput> {

    public typealias Input = SdkHttpRequest

    public typealias Output = OperationOutput<OperationStackOutput>

    let handler: H

    public init(handler: H) {
        self.handler = handler
    }

    public func handle(context: Smithy.Context, input: Input) async throws -> Output {
       return try await handler.handle(context: context, input: input)
    }
}

public struct OperationOutput<Output> {
    public var httpResponse: HttpResponse
    public var output: Output?

    public init(httpResponse: HttpResponse, output: Output? = nil) {
        self.httpResponse = httpResponse
        self.output = output
    }
}
