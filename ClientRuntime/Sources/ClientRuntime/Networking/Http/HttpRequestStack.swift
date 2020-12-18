// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.
 
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
    
    public mutating func add<M: Middleware>(to phase: HttpRequestPhases, position: Position, middleware: M) where M.TContext == HttpRequestContext, M.TSubject == SdkHttpRequest, M.TError == ClientError {
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
    func getPhase() -> Phase<HttpRequestContext, SdkHttpRequest, ClientError> {
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
