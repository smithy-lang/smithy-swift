/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// this class will implement Handler per new middleware implementation
public class SdkHttpClient {

    let engine: HttpClientEngine

    public init(engine: HttpClientEngine, config: HttpClientConfiguration) {
        self.engine = engine
    }

    public func getHandler<Output>() -> AnyHandler<SdkHttpRequest, OperationOutput<Output>, HttpContext> {
        let clientHandler = ClientHandler<Output>(engine: engine)
        return clientHandler.eraseToAnyHandler()
    }

    func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        return try await engine.execute(request: request)
    }
}

struct ClientHandler<Output>: Handler {
    let engine: HttpClientEngine
    func handle(context: HttpContext, input: SdkHttpRequest) async throws -> OperationOutput<Output> {
        let httpResponse: HttpResponse

        if context.shouldForceH2(), let crtEngine = engine as? CRTClientEngine {
            httpResponse = try await crtEngine.executeHTTP2Request(request: input)
        } else {
            httpResponse = try await engine.execute(request: input)
        }

        return OperationOutput<Output>(httpResponse: httpResponse)
    }

    typealias Input = SdkHttpRequest
    typealias Output = OperationOutput<Output>
    typealias Context = HttpContext
}
