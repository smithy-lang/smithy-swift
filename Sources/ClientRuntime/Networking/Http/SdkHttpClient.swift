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

    public func getHandler<OperationStackOutput>()
        -> AnyHandler<SdkHttpRequest, OperationOutput<OperationStackOutput>, HttpContext> {

        let clientHandler = ClientHandler<OperationStackOutput>(engine: engine)
        return clientHandler.eraseToAnyHandler()
    }

    func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        return try await engine.execute(request: request)
    }
}

struct ClientHandler<OperationStackOutput>: Handler {
    let engine: HttpClientEngine
    func handle(context: HttpContext, input: SdkHttpRequest) async throws -> OperationOutput<OperationStackOutput> {
        let httpResponse: HttpResponse

        if context.shouldForceH2(), let crtEngine = engine as? CRTClientEngine {
            httpResponse = try await crtEngine.executeHTTP2Request(request: input)
        } else {
            httpResponse = try await engine.execute(request: input)
        }

        return OperationOutput<OperationStackOutput>(httpResponse: httpResponse)
    }

    typealias Input = SdkHttpRequest
    typealias Output = OperationOutput<OperationStackOutput>
    typealias Context = HttpContext
}
