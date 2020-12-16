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
    
    public func execute(request: SdkHttpRequest, completion: @escaping NetworkResult) {
        engine.execute(request: request, completion: completion)
    }
    
    public func execute<OutputType, OutputError>(request: SdkHttpRequest,
                                                 context: Context<OutputType, OutputError>,
                                                 completion: @escaping (SdkResult<OutputType, OutputError>) -> Void) {
        engine.execute(request: request) { (httpResult) in
            
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
                        //TODO: double check that this is the error we should be passing back to the service client.
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
