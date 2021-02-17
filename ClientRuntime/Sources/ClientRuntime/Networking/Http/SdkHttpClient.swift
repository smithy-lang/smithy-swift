/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// this class will implement Handler per new middleware implementation
public class SdkHttpClient {
    
    let engine: HttpClientEngine
    
    public init(engine: HttpClientEngine? = nil, config: HttpClientConfiguration) throws {
        if let engine = engine {
            self.engine = engine
        } else {
            // CRT is the default engine
            self.engine = try CRTClientEngine()
        }
    }
    
    public func getHandler<Output: HttpResponseBinding,
                           OutputError: HttpResponseBinding>() -> AnyHandler<SdkHttpRequest,
                                                                             OperationOutput<Output,
                                                                                               OutputError>,
                                                                             HttpContext> {
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
    func handle(context: HttpContext, input: SdkHttpRequest) -> Result<OperationOutput<Output, OutputError>, Error> {
        let result = engine.execute(request: input)
        do {
            let httpResponse = try result.get()
            let output = OperationOutput<Output, OutputError>(httpResponse: httpResponse)
            return .success(output)
        } catch let err {
            return .failure(err)
        }
    }

    typealias Input = SdkHttpRequest

    typealias Output = OperationOutput<Output, OutputError>

    typealias Context = HttpContext
}
