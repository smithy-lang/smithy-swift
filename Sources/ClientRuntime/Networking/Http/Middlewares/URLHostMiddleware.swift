//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyAPI.OperationContext
import SmithyAPI

public struct URLHostMiddleware<OperationStackInput, OperationStackOutput>: Middleware {
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
              updateAttributes(attributes: context)
              return try await next.handle(context: context, input: input)
          }

    private func updateAttributes(attributes: OperationContext) {
        if let host = host {
            attributes.set(key: AttributeKey<String>(name: "Host"), value: host)
        }
        if let hostPrefix = hostPrefix {
            attributes.set(key: AttributeKey<String>(name: "HostPrefix"), value: hostPrefix)
        }
    }

    public typealias MInput = OperationStackInput
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = OperationContext
}

extension URLHostMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeSerialization(context: some MutableInput<InputType, AttributesType>) async throws {
        // This is an interceptor and not a serializer because endpoints are used to resolve the host
        updateAttributes(attributes: context.getAttributes())
    }
}
