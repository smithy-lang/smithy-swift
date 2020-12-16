/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

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
    
    func execute(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        engine.execute(request: request, completion: completion)
    }
    
    public func execute<OutputType, OutputError>(context: Context<OutputType, OutputError>,
                                                 completion: @escaping (SdkResult<OutputType, OutputError>) -> Void) {
        
        engine.execute(request: context.request) { (httpResult) in
            
            switch httpResult {
            case .failure(let httpClientErr):
                completion(.failure(.client(ClientError.networkError(httpClientErr))))
                return
                
            case .success(let httpResponse):
                if (200..<300).contains(httpResponse.statusCode.rawValue) {
                    do {
                        let output = try OutputType(httpResponse: httpResponse,
                                                    decoder: context.decoder)
                        completion(.success(output))
                    } catch let err {
                        completion(.failure(.client(.deserializationFailed(err))))
                        return
                    }
                } else {
                    do {
                        let error = try OutputError(httpResponse: httpResponse,
                                                    decoder: context.decoder)
                        completion(.failure(SdkError.service(error)))
                    } catch let err {
                        completion(.failure(.client(.deserializationFailed(err))))
                        return
                    }
                }
            }
        }
    }
    
    public func execute<Output, OutputError>(requestContext: HttpRequestContext,
                                             requestStack: HttpRequestStack,
                                             responseContext: HttpResponseContextBuilder,
                                             responseStack: HttpResponseStack,
                                             completion: @escaping (SdkResult<Output, OutputError>) -> Void) {
        let request = requestStack.execute(context: requestContext,
                                           subject: SdkHttpRequest(method: .get,
                                                                   endpoint: Endpoint(host: ""),
                                                                   headers: Headers())) //need to turn this into a builder
        switch request {
        case .success(let request):
            engine.execute(request: request) { (httpResult) in
                
                switch httpResult {
                case .failure(let httpClientErr):
                    completion(.failure(.client(ClientError.networkError(httpClientErr))))
                    return
                    
                case .success(let httpResponse):
                    if (200..<300).contains(httpResponse.statusCode.rawValue) {
                        let context = responseContext
                            .withResponse(value: httpResponse)
                            .build()
                        let response = responseStack.execute(context: context,
                                                             subject: httpResponse)
                        switch response {
                        case .failure(let error):
                            if let mappedError = error as? SdkError<OutputError> {
                                completion(.failure(mappedError))
                            } else {
                                completion(.failure(SdkError.unknown(error)))
                            }
                        case .success(let response):
                            completion(.success(response as! Output))
                        }
                    }
                }
            }
        case .failure(let error):
            completion(.failure(.client(error)))
        }
    }
    
    public func close() {
        engine.close()
    }
}
