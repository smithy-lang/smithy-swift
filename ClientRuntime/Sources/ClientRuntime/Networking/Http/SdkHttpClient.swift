/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

///this class will implement Handler per new middleware implementation
public class SdkHttpClient {
    
    let engine: HttpClientEngine
    
    public init(engine: HttpClientEngine? = nil, config: HttpClientConfiguration) throws {
        if let engine = engine {
            self.engine = engine
        } else {
            //CRT is the default engine
            self.engine = try CRTClientEngine()
        }
    }
    
    public func getHandler<Output: HttpResponseBinding,
                           OutputError: HttpResponseBinding>() -> AnyHandler<SdkHttpRequest,
                                                                             DeserializeOutput<Output,
                                                                                               OutputError>,
                                                                             HttpContext> {
        let clientHandler = ClientHandler<Output, OutputError>(engine: engine)
        return clientHandler.eraseToAnyHandler()
    }
    
    func execute(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        engine.executeWithClosure(request: request, completion: completion)
    }
    
    
    typealias Input = SdkHttpRequest
    
    typealias Output = DeserializeOutput<Output, OutputError>
    
    typealias Context = HttpContext
}

struct ClientHandler<Output: HttpResponseBinding, OutputError: HttpResponseBinding>: Handler {
    let engine: HttpClientEngine
    func handle(context: HttpContext, input: SdkHttpRequest) -> Result<DeserializeOutput<Output, OutputError>, Error> {
        let result = engine.execute(request: input)
        do {
            let httpResponse = try result.get()
            let output = DeserializeOutput<Output, OutputError>(httpResponse: httpResponse)
            return .success(output)
        } catch let err {
            return .failure(err)
        }
    }

    typealias Input = SdkHttpRequest

    typealias Output = DeserializeOutput<Output, OutputError>

    typealias Context = HttpContext
}
