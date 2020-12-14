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

public struct HttpRequestStack {
    var middlewareStack: MiddlewareStack<HttpRequestContext, SdkHttpRequest, ClientError>

    public init() {

        
        let middlewareStack = MiddlewareStack<HttpRequestContext,
                                          SdkHttpRequest,
                                          ClientError>(phases: HttpRequestPhases.initialize.getPhase(),
                                                       HttpRequestPhases.build.getPhase(),
                                                       HttpRequestPhases.finalize.getPhase())
        self.middlewareStack = middlewareStack
    }
    
    public func execute(context: HttpRequestContext, subject: SdkHttpRequest) -> Result<SdkHttpRequest, ClientError> {
        middlewareStack.execute(context: context, subject: subject)
    }
    
    public mutating func add(to phase: HttpRequestPhases,
                    position: Position,
                    id: String,
                    handler: @escaping HandlerFunction<HttpRequestContext, SdkHttpRequest, ClientError>) {
        
        middlewareStack.intercept(phase.getPhase(), position: position, id: id, handler: handler)
    }
    
    public mutating func add(to phase: HttpRequestPhases, position: Position, middleware: AnyMiddleware<HttpRequestContext, SdkHttpRequest, ClientError>){
        middlewareStack.intercept(phase: phase.getPhase(),
                             position: position,
                             middleware: middleware)
    }
}

public enum HttpRequestPhases {
    case initialize
    case build
    case finalize
}

extension HttpRequestPhases {
    func getPhase<HttpRequestContext, SdkHttpRequest, ClientError>() -> Phase<HttpRequestContext, SdkHttpRequest, ClientError> {
        switch self {
        case .initialize:
            return Phase<HttpRequestContext, SdkHttpRequest, ClientError>(name: "Initialize")
        case .build:
            return Phase<HttpRequestContext, SdkHttpRequest, ClientError>(name: "Build")
        case .finalize:
            return Phase<HttpRequestContext, SdkHttpRequest, ClientError>(name: "Finalize")
        }
    }
}
