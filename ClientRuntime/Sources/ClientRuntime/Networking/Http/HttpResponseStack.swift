//// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//// SPDX-License-Identifier: Apache-2.0.
//
//public struct HttpResponseStack {
//    var middlewareStack: MiddlewareStack<HttpResponseContext, Any, Error>
//    
//    public init() {
//        let middlewareStack = MiddlewareStack<HttpResponseContext,
//                                         Any,
//                                         Error>(phases: HttpResponsePhases.deserialize.getPhase(),
//                                                HttpResponsePhases.finalize.getPhase())
//        self.middlewareStack = middlewareStack
//    }
//    
//    public func execute(context: HttpResponseContext, subject: Any) -> Result<Any, Error> {
//        middlewareStack.execute(context: context, subject: subject)
//    }
//    
//    public mutating func add(to phase: HttpResponsePhases,
//                             position: Position,
//                             id: String,
//                             handler: @escaping HandlerFunction<HttpResponseContext, Any, Error>) {
//        
//        middlewareStack.intercept(phase.getPhase(), position: position, id: id, handler: handler)
//    }
//    
//    public mutating func add(to phase: HttpResponsePhases,
//                             position: Position,
//                             middleware: AnyMiddleware<HttpResponseContext, Any, Error>) {
//        middlewareStack.intercept(phase: phase.getPhase(),
//                             position: position,
//                             middleware: middleware)
//    }
//}
//
//public enum HttpResponsePhases {
//    case response
//    case deserialize
//    case finalize
//}
//
//extension HttpResponsePhases {
//    func getPhase() -> Phase<HttpResponseContext, Any, Error> {
//        switch self {
//        case .response:
//            return Phase<HttpResponseContext, Any, Error>(name: "Response")
//        case .deserialize:
//            return Phase<HttpResponseContext, Any, Error>(name: "Deserialize")
//        case .finalize:
//            return Phase<HttpResponseContext, Any, Error>(name: "Finalize")
//        }
//    }
//}
