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

public struct HttpResponseStack {
    var middleware: MiddlewareStack<HttpResponseContext, Any, Error>

    public init() {
        var middleware = MiddlewareStack<HttpResponseContext,
                                          Any,
                                          Error>(phases: HttpResponsePhases.deserialize.getPhase(),
                                                       HttpResponsePhases.finalize.getPhase())
        
        middleware.intercept(HttpResponsePhases.deserialize.getPhase(), position: .before, id: "Deserialize") { (context, subject) -> Result<OutputType, ClientError> in
            let decoder = context.getDecoder()
            let httpResponse = context.response
            do {
                let output = try outputType.init(httpResponse: httpResponse,
                                        decoder: decoder)
                return .success(output)
            }
            catch(let error) {
                return .failure(ClientError.deserializationFailed(error))
            }
        }
        self.middleware = middleware
    }
    
    public func execute(context: HttpResponseContext, subject: Any) -> Result<Any, Error> {
        middleware.execute(context: context, subject: subject)
    }
    
    public mutating func add(to phase: HttpResponsePhases,
                    position: Position,
                    id: String,
                    handler: @escaping HandlerFunction<HttpResponseContext, Any, Error>) {
        
        middleware.intercept(phase.getPhase(), position: position, id: id, handler: handler)
    }
}

public enum HttpResponsePhases {
    case deserialize
    case finalize
}

extension HttpResponsePhases {
    func getPhase<HttpResponseContext, ResponseSubject, ResponseError>() -> Phase<HttpResponseContext, ResponseSubject, ResponseError> {
        switch self {
        case .deserialize:
            return Phase<HttpResponseContext, ResponseSubject, ResponseError>(name: "Deserialize")
        case .finalize:
            return Phase<HttpResponseContext, ResponseSubject, ResponseError>(name: "Finalize")
        }
    }
}
