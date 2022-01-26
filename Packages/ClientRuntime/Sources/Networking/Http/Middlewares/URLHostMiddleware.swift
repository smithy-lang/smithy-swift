//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
public struct URLHostMiddleware<Input: Reflection & Encodable, Output: HttpResponseBinding, Error>: ClientRuntime.Middleware {
    public let id: Swift.String = "\(String(describing: Input.self))URLHostMiddleware"

    let host: Swift.String?

    public init(host: Swift.String? = nil) {
        self.host = host
    }

    public func handle<H>(context: Context,
                  input: MInput,
                  next: H) -> Swift.Result<MOutput, MError>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context,
    Self.MError == H.MiddlewareError
    {
        var copiedContext = context
        if let host = host {
            copiedContext.attributes.set(key: AttributeKey<String>(name: "Host"), value: host)
        }
        return next.handle(context: copiedContext, input: input)
    }

    public typealias MInput = Input
    public typealias MOutput = ClientRuntime.OperationOutput<Output>
    public typealias Context = ClientRuntime.HttpContext
    public typealias MError = ClientRuntime.SdkError<Error>
}
