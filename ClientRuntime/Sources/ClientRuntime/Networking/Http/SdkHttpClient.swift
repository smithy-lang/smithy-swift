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
    
    public func execute<ResponseSubject: HttpResponseBinding,
                        OutputError: HttpResponseBinding>(request: SdkHttpRequest,
                                                          responseContext: HttpResponseContextBuilder,
                                                          responseSubject: ResponseSubject.Type,
                                                          responseStack: HttpResponseStack<ResponseSubject, OutputError>,
                                                          outputError: OutputError.Type,
                                                          completion: @escaping (SdkResult<ResponseSubject, OutputError>) -> Void) {
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
                                                         subject: responseSubject)
                    switch response {
                    case .failure(let error):
                        completion(.failure(.client(.deserializationFailed(error))))
                    case .success(let response):
                        completion(.success(response))
                    }
                } else {
                    do {
                        let context = responseContext.build()
                        let decoder = context.getDecoder()
                        let error = try OutputError(httpResponse: httpResponse,
                                                    decoder: decoder)
                        completion(.failure(SdkError.service(error)))
                    } catch let err {
                        completion(.failure(.client(.deserializationFailed(err))))
                        return
                    }
                }
            }
        }
    }
    
    public func close() {
        engine.close()
    }
}
