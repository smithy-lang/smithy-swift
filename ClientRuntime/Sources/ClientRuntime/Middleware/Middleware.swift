// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol Middleware {
<<<<<<< HEAD
    associatedtype MInput
    associatedtype MOutput
    associatedtype Context: MiddlewareContext
    
    /// The middleware ID
    var id: String { get }
    
    func handle<H: Handler>(context: Context,
                            input: MInput,
                            next: H) -> Result<MOutput, Error>
    where H.Input == MInput, H.Output == MOutput, H.Context == Context
}

extension Middleware {
    func eraseToAnyMiddleware() -> AnyMiddleware<MInput, MOutput, Context> {
        return AnyMiddleware(self)
    }
=======
    //unique id for the middleware
    var id: String {get set}
    
    // Performs the middleware's handling of the input, returning the output,
    // or error. The middleware can invoke the next Responder if handling should
    // continue.
    func handleMiddleware(to context: ExecutionContext,
                          input: Any,
                          next: Responder) -> (Any?, Error?)
>>>>>>> e23f14b... saving progress
}
