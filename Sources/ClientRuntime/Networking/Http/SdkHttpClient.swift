/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// this class will implement Handler per new middleware implementation
public class SdkHttpClient: ExecuteRequest {

    let engine: HTTPClient

    public init(engine: HTTPClient, config: HttpClientConfiguration) {
        self.engine = engine
    }

    public func execute(request: SdkHttpRequest, attributes: HttpContext) async throws -> HttpResponse {
        if attributes.shouldForceH2(), let crtEngine = engine as? CRTClientEngine {
            return try await crtEngine.executeHTTP2Request(request: request)
        } else {
            return try await engine.send(request: request)
        }
    }

    public func getHandler<OperationStackOutput>()
        -> AnyHandler<SdkHttpRequest, OperationOutput<OperationStackOutput>, HttpContext> {

        let clientHandler = ClientHandler<OperationStackOutput>(client: self)
        return clientHandler.eraseToAnyHandler()
    }

    func send(request: SdkHttpRequest) async throws -> HttpResponse {
        return try await engine.send(request: request)
    }
}

private struct ClientHandler<OperationStackOutput>: Handler {
    let client: SdkHttpClient

    func handle(context: HttpContext, input: SdkHttpRequest) async throws -> OperationOutput<OperationStackOutput> {
        let httpResponse = try await client.execute(request: input, attributes: context)
        return OperationOutput<OperationStackOutput>(httpResponse: httpResponse)
    }

    typealias Input = SdkHttpRequest
    typealias Output = OperationOutput<OperationStackOutput>
    typealias Context = HttpContext
}
