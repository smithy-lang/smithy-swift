//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct URLHostMiddleware<OperationStackInput,
                                OperationStackOutput>: Middleware {
    public let id: String = "\(String(describing: OperationStackInput.self))URLHostMiddleware"

    let host: String?
    let hostPrefix: String?

    public init(host: String? = nil, hostPrefix: String? = nil) {
        self.host = host
        self.hostPrefix = hostPrefix
    }

    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) async throws -> MOutput
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              if let host = host {
                  context.attributes.set(key: AttributeKey<String>(name: "Host"),
                                         value: host)
              }
              if let hostPrefix = hostPrefix {
                  context.attributes.set(key: AttributeKey<String>(name: "HostPrefix"),
                                         value: hostPrefix)
              }
              return try await next.handle(context: context, input: input)
          }

    public typealias MInput = OperationStackInput
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
