//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct LoggerMiddleware<Output>: Middleware {

    public let id: String = "Logger"

    let clientLogMode: ClientLogMode

    public init(clientLogMode: ClientLogMode) {
        self.clientLogMode = clientLogMode
    }

    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<Output>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {

        guard let logger = context.getLogger() else {
            return try await next.handle(context: context, input: input)
        }

        if clientLogMode == .request || clientLogMode == .requestAndResponse {
            logger.debug("Request: \(input.debugDescription)")
        } else if clientLogMode == .requestAndResponseWithBody || clientLogMode == .requestWithBody {
            logger.debug("Request: \(input.debugDescriptionWithBody)")
        }

        let response = try await next.handle(context: context, input: input)

        if clientLogMode == .response || clientLogMode == .requestAndResponse {
            logger.debug("Response: \(response.httpResponse.debugDescription)")
        } else if clientLogMode == .requestAndResponseWithBody || clientLogMode == .responseWithBody {
            logger.debug("Response: \(response.httpResponse.debugDescriptionWithBody)")
        }

        return response
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext
}
