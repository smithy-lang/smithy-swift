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

public struct MiddlewareStack<TContext, TSubject, TError: Error> {
    
    var root: AnyMiddleware<TContext, TSubject, TError>?
    var phases: [Phase<TContext, TSubject, TError>]
    var defaultHandler: HandlerFunction<TContext, TSubject, TError>
    
    init(phases: Phase<TContext, TSubject, TError>...,
         defaultHandler: @escaping HandlerFunction<TContext, TSubject, TError> = {context, result in
            return .success(result)
        }) {
        
        self.phases = phases
       
        if phases.count > 1 {
            if let orderedMiddleware = phases.first?.orderedMiddleware,
               let middleware = orderedMiddleware.orderedItems.first?.value{
                self.root = middleware
            }
        }
        self.defaultHandler = defaultHandler
    }
    /// This execute will execute the stack and use either a next you set when you instantiated the stack or the default in the chain
    func execute(context: TContext, subject: TSubject) -> Result<TSubject, TError> {
        let handlerFn = HandlerFunctionWrapper(defaultHandler)
        var handler = AnyHandler<TContext, TSubject, TError>(handlerFn)
        for phase in phases {
            let order = phase.orderedMiddleware.orderedItems
            let reversedCollection = (0...(order.count-1)).reversed()
            for index in reversedCollection {
                let composedHandler = ComposedHandler(handler, order[index].value)
                handler = AnyHandler(composedHandler)
            }
        }
        let result = handler.handle(context: context, subject: subject)
        return result
    }
    
    /// This execute will execute the stack and use your next as the last closure in the chain
    func execute(context: TContext,
                 subject: TSubject,
                 next: @escaping HandlerFunction<TContext, TSubject, TError>) -> Result<TSubject, TError> {
        
        let handlerFn = HandlerFunctionWrapper(next)
        var handler = AnyHandler<TContext, TSubject, TError>(handlerFn)
        for phase in phases {
            let order = phase.orderedMiddleware.orderedItems
            let reversedCollection = (0...(order.count-1)).reversed()
            for index in reversedCollection {
                let composedHandler = ComposedHandler(handler, order[index].value)
                handler = AnyHandler(composedHandler)
            }
        }
        let result = handler.handle(context: context, subject: subject)
        return result
    }
    
    mutating func intercept<M:Middleware>(phase: Phase<TContext, TSubject, TError>, position: Position, middleware: M)
    where M.TContext == TContext, M.TSubject == TSubject, M.TError == TError
    {
        guard let index = phases.firstIndex(where: { $0.name == phase.name}) else { return }
        var orderedMiddleware = OrderedGroup<TContext, TSubject, TError>()
        orderedMiddleware.add(middleware: AnyMiddleware(middleware), position: position)
        phases[index].orderedMiddleware = orderedMiddleware
        
        resetRoot()
    }
    
    /// Convenience function for passing a closure directly:
    ///
    /// ```
    /// stack.intercept(phase, position: .after, id: "Add Header") { ... }
    /// ```
    ///
    mutating func intercept(_ phase: Phase<TContext, TSubject, TError>,
                   position: Position,
                   id: String,
                   handler: @escaping HandlerFunction<TContext, TSubject, TError>) {
        let handlerFn = HandlerFunctionWrapper(handler)
        let anyHandler = AnyHandler<TContext, TSubject, TError>(handlerFn)
        let middleware = ComposedMiddleware<TContext, TSubject, TError>(anyHandler, id: id)
        //get next from exisiting phase in the right position
        guard let index = phases.firstIndex(where: {$0.name == phase.name}) else { return }
        var orderedMiddleware = OrderedGroup<TContext, TSubject, TError>()
        orderedMiddleware.add(middleware: AnyMiddleware(middleware), position: position)
        phases[index].orderedMiddleware = orderedMiddleware
        
        //reset root
        resetRoot()
    }
    /// resets the root function that is called when the stack is kicked off
    private mutating func resetRoot() {
        let firstPhase = phases[0]
        if let middleware = firstPhase.orderedMiddleware.orderedItems.first?.value {
            self.root = middleware
        }
    }
}
