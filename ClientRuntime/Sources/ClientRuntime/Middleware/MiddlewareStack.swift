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
import AwsCommonRuntimeKit

public struct MiddlewareStack<TContext, TSubject, TError: Error> {
    
    var root: AnyMiddleware<TContext, TSubject, TError>
    var phases: [Phase<TContext, TSubject, TError>]
    
    init(phases: Phase<TContext, TSubject, TError>...) {
        let firstPhase = phases[0]
        let middleware = firstPhase.orderedMiddleware.items[0].value  //get first item of the list of middleware and get value
        self.root = middleware
        self.phases = phases
    }
    
    func execute(context: TContext,
                 subject: TSubject,
                 next: @escaping HandlerFunc<TContext, TSubject, TError>) -> Result<TSubject, TError> {
        
        let handlerFn = HandlerFn(next)
        var handler = AnyHandler<TContext, TSubject, TError>(handlerFn)
        for phase in phases {
            let order = phase.orderedMiddleware.items
            for index in stride(from: 0, to: order.count - 1, by: -1) {
                let composedHandler = ComposedHandler(handler, order[index].value)
                handler = AnyHandler(composedHandler)
            }
        }
        let result = handler.handle(context: context, subject: subject)
        return result
    }
    
    func intercept<M:Middleware>(phase: Phase<TContext, TSubject, TError>, position: Position, middleware: M)
    where M.TContext == TContext, M.TSubject == TSubject, M.TError == TError
    {
        var phaseToBeEdited = phases.first { $0.name == phase.name}
        phaseToBeEdited?.orderedMiddleware.add(middleware: AnyMiddleware(middleware), position: position)
    }
    
    /// Convenience function for passing a closure directly:
    ///
    /// ```
    /// stack.intercept(phase) { ... }
    /// ```
    ///
    func intercept(_ phase: Phase<TContext, TSubject, TError>,
                   position: Position,
                   handler: @escaping HandlerFunc<TContext, TSubject, TError>) {
        let handlerFn = HandlerFn(handler)
        let handler = AnyHandler<TContext, TSubject, TError>(handlerFn)
        //how do you make middleware if just given a handler?
        
    }
}
