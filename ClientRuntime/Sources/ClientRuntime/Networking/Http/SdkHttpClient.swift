//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

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
