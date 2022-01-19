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
    
    public func getHandler<Output: HttpResponseBinding,
                           OutputError: HttpResponseBinding>() -> AnyHandler<SdkHttpRequest,
                                                                             OperationOutput<Output>,
                                                                             HttpContext,
                                                                             SdkError<OutputError>> {
        let clientHandler = ClientHandler<Output, OutputError>(engine: engine)
        return clientHandler.eraseToAnyHandler()
    }
    
    func execute(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        engine.executeWithClosure(request: request, completion: completion)
    }
    
    public func close() {
        engine.close()
    }
    
}

struct ClientHandler<Output: HttpResponseBinding, OutputError: HttpResponseBinding>: Handler {
    let engine: HttpClientEngine
    func handle(context: HttpContext, input: SdkHttpRequest) -> Result<OperationOutput<Output>, SdkError<OutputError>> {
        let result = engine.execute(request: input)
        do {
            let httpResponse = try result.get()
            let output = OperationOutput<Output>(httpResponse: httpResponse)
            return .success(output)
        } catch let err {
            return .failure(.client(ClientError.networkError(err)))
        }
    }

    typealias Input = SdkHttpRequest

    typealias Output = OperationOutput<Output>

    typealias Context = HttpContext
    
    typealias MiddlewareError = SdkError<OutputError>
}
