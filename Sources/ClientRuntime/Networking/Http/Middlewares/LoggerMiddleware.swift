//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.LogAgent
import class Smithy.Context
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

public struct LoggerMiddleware<OperationStackInput, OperationStackOutput>: Middleware {

    public let id: String = "Logger"

    let clientLogMode: ClientLogMode

    public init(clientLogMode: ClientLogMode) {
        self.clientLogMode = clientLogMode
    }

    public func handle<H>(context: Context,
                          input: HTTPRequest,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output {

        guard let logger = context.getLogger() else {
            return try await next.handle(context: context, input: input)
        }

        logRequest(logger: logger, request: input)

        let response = try await next.handle(context: context, input: input)

        logResponse(logger: logger, response: response.httpResponse)

        return response
    }

    private func logRequest(logger: any LogAgent, request: HTTPRequest) {
        if clientLogMode == .requestWithoutAuthorizationHeader {
            logger.debug("Request: \(request.debugDescriptionWithoutAuthorizationHeader)")
        } else if clientLogMode == .request || clientLogMode == .requestAndResponse {
            logger.debug("Request: \(request.debugDescription)")
        } else if clientLogMode == .requestAndResponseWithBody || clientLogMode == .requestWithBody {
            logger.debug("Request: \(request.debugDescriptionWithBody)")
        }
    }

    private func logResponse(logger: any LogAgent, response: HTTPResponse) {
        if clientLogMode == .response || clientLogMode == .requestAndResponse {
            logger.debug("Response: \(response.debugDescription)")
        } else if clientLogMode == .requestAndResponseWithBody || clientLogMode == .responseWithBody {
            logger.debug("Response: \(response.debugDescriptionWithBody)")
        }
    }

    public typealias MInput = HTTPRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
}

extension LoggerMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func readBeforeTransmit(
        context: some AfterSerialization<InputType, RequestType>
    ) async throws {
        guard let logger = context.getAttributes().getLogger() else {
            return
        }

        logRequest(logger: logger, request: context.getRequest())
    }

    public func readAfterTransmit(
        context: some BeforeDeserialization<InputType, RequestType, ResponseType>
    ) async throws {
        guard let logger = context.getAttributes().getLogger() else {
            return
        }

        logResponse(logger: logger, response: context.getResponse())
    }
}
