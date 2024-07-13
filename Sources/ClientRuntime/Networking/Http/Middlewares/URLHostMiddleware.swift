//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

public struct URLHostMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "\(String(describing: OperationStackInput.self))URLHostMiddleware"

    let host: String?
    let hostPrefix: String?

    public init(host: String? = nil, hostPrefix: String? = nil) {
        self.host = host
        self.hostPrefix = hostPrefix
    }

    private func updateAttributes(attributes: Smithy.Context) {
        if let host = host {
            attributes.host = host
        }
        if let hostPrefix = hostPrefix {
            attributes.hostPrefix = hostPrefix
        }
    }
}

extension URLHostMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeSerialization(context: some MutableInput<InputType>) async throws {
        // This is an interceptor and not a serializer because endpoints are used to resolve the host
        updateAttributes(attributes: context.getAttributes())
    }
}
