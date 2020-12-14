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

struct DeserializeErrorMiddleware<OutputError: HttpResponseBinding>: Middleware {
    var id: String = "Deserialize"
    
    let outputErrorType: OutputError.Type
    
    func handle<H>(context: HttpResponseContext, subject: Any, next: H) -> Result<Any, Error> where H : Handler, Self.TContext == H.TContext, Self.TError == H.TError, Self.TSubject == H.TSubject {
        let decoder = context.getDecoder()
        let httpResponse = context.response
        do {
            let error = try OutputError(httpResponse: httpResponse,
                                        decoder: decoder)
            
            completion(.failure(SdkError.service(error)))
        }
//        catch(let error) {
//            return .failure(ClientError.deserializationFailed(error))
//        }
        //TODO: handle error propagation
        
    }
    
    typealias TContext = HttpResponseContext
    
    typealias TSubject = Any
    
    typealias TError = Error
}

