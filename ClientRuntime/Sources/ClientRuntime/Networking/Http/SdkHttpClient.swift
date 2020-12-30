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

    }
    
//    public func handle(context: Context, input: SdkHttpRequest) -> Result<DeserializeOutput<Output, OutputError>, Error> {
//        execute(request: input) { (httpResult) -> Result<HttpResponse, Error> in
//            switch httpResult {
//            case .failure(let httpClientErr):
//                return .failure(ClientError.networkError(httpClientErr))
//            case .success(let httpResponse):
//                let output = DeserializeOutput<Output, OutputError>(httpResponse: httpResponse)
//                return .success(output)
//            }
//        }
//    }
    
    func execute(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        engine.execute(request: request, completion: completion)
    }
    
    public func close() {
        engine.close()
    }
    
}


struct ClientHandler<Output: HttpResponseBinding, OutputError: HttpResponseBinding>: Handler {
    let engine: HttpClientEngine
    func handle(context: HttpContext, input: SdkHttpRequest) -> Result<DeserializeOutput<Output, OutputError>, Error> {
    engine.execute(request: input) { (result) -> Result<HttpResponse, Error> in
            return result.map { (httpResponse) -> Result<DeserializeOutput<Output, OutputError>, Error> in
                let output = DeserializeOutput<Output, OutputError>(httpResponse: HttpResponse)
                return output
            }
        }
        
    }
    
    
    typealias Input = SdkHttpRequest
    
    typealias Output = DeserializeOutput<Output, OutputError>
    
    typealias Context = HttpContext
}
