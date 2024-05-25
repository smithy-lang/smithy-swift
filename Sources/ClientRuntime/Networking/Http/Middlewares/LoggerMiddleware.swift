//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyAPI.LogAgent
import class SmithyAPI.OperationContext
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.HttpResponse

public struct LoggerMiddleware<OperationStackInput, OperationStackOutput>: Middleware {

    public let id: String = "Logger"

    let clientLogMode: ClientLogMode

    public init(clientLogMode: ClientLogMode) {
        self.clientLogMode = clientLogMode
    }

    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {

        guard let logger = context.getLogger() else {
            return try await next.handle(context: context, input: input)
        }

        logRequest(logger: logger, request: input)

        let response = try await next.handle(context: context, input: input)

        logResponse(logger: logger, response: response.httpResponse)

        return response
    }

    private func logRequest(logger: any LogAgent, request: SdkHttpRequest) {
        if clientLogMode == .request || clientLogMode == .requestAndResponse {
            logger.debug("Request: \(request.debugDescription)")
        } else if clientLogMode == .requestAndResponseWithBody || clientLogMode == .requestWithBody {
            logger.debug("Request: \(request.debugDescriptionWithBody)")
        }
    }

    private func logResponse(logger: any LogAgent, response: HttpResponse) {
        if clientLogMode == .response || clientLogMode == .requestAndResponse {
            logger.debug("Response: \(response.debugDescription)")
        } else if clientLogMode == .requestAndResponseWithBody || clientLogMode == .responseWithBody {
            logger.debug("Response: \(response.debugDescriptionWithBody)")
        }
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = OperationContext
}

extension LoggerMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func readBeforeTransmit(
        context: some AfterSerialization<InputType, RequestType, AttributesType>
    ) async throws {
        guard let logger = context.getAttributes().getLogger() else {
            return
        }

        logRequest(logger: logger, request: context.getRequest())
    }

    public func readAfterTransmit(
        context: some BeforeDeserialization<InputType, RequestType, ResponseType, AttributesType>
    ) async throws {
        guard let logger = context.getAttributes().getLogger() else {
            return
        }

        logResponse(logger: logger, response: context.getResponse())
    }
}
