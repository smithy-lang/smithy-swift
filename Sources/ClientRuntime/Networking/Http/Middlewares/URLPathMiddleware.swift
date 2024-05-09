//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct URLPathMiddleware<OperationStackInput, OperationStackOutput>: Middleware {
    public let id: Swift.String = "\(String(describing: OperationStackInput.self))URLPathMiddleware"

    let urlPrefix: Swift.String?
    let urlPathProvider: URLPathProvider<OperationStackInput>

    public init(urlPrefix: Swift.String? = nil, _ urlPathProvider: @escaping URLPathProvider<OperationStackInput>) {
        self.urlPrefix = urlPrefix
        self.urlPathProvider = urlPathProvider
    }

    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) async throws -> MOutput
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              try updateAttributes(input: input, attributes: context)
              return try await next.handle(context: context, input: input)
          }

    private func updateAttributes(input: OperationStackInput, attributes: HttpContext) throws {
        guard var urlPath = urlPathProvider(input) else {
           let message = "Creating the url path failed, a required property in the path was nil"
           throw ClientError.pathCreationFailed(message)
        }
        if let urlPrefix = urlPrefix, !urlPrefix.isEmpty {
            urlPath = "\(urlPrefix)\(urlPath)"
        }
        attributes.set(key: AttributeKey<String>(name: "Path"), value: urlPath)
    }

    public typealias MInput = OperationStackInput
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}

extension URLPathMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeSerialization(context: some MutableInput<InputType, AttributesType>) async throws {
        // This is an interceptor and not a serializer because endpoints are used to resolve the host
        try updateAttributes(input: context.getInput(), attributes: context.getAttributes())
    }
}
