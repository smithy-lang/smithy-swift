// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public typealias HandleInitialize = (_ context: ExecutionContext, _ input: Any) -> (Any, Error?)
public protocol Middleware {
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
}
