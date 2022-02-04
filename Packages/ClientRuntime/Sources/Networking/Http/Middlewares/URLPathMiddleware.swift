//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct URLPathMiddleware<OperationStackInput: Encodable & Reflection,
                                OperationStackOutput: HttpResponseBinding,
                                OperationStackError: HttpResponseBinding>: ClientRuntime.Middleware {
    public let id: Swift.String = "\(String(describing: OperationStackInput.self))URLPathMiddleware"

    let urlPrefix: Swift.String?
    let urlPath: String

    public init(urlPath: String, urlPrefix: Swift.String? = nil) {
        self.urlPath = urlPath
        self.urlPrefix = urlPrefix
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
        var urlPath = urlPath
        if let urlPrefix = urlPrefix, !urlPrefix.isEmpty {
            urlPath = "\(urlPrefix)\(urlPath)"
        }
        var copiedContext = context
        copiedContext.attributes.set(key: AttributeKey<String>(name: "Path"), value: urlPath)
        return next.handle(context: copiedContext, input: input)
    }

    public typealias MInput = OperationStackInput
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
