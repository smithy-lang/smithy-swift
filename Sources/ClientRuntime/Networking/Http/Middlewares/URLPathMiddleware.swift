//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import enum SmithyHTTPAPI.HTTPClientError

public struct URLPathMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: Swift.String = "\(String(describing: OperationStackInput.self))URLPathMiddleware"

    let urlPrefix: Swift.String?
    let urlPathProvider: URLPathProvider<OperationStackInput>

    public init(urlPrefix: Swift.String? = nil, _ urlPathProvider: @escaping URLPathProvider<OperationStackInput>) {
        self.urlPrefix = urlPrefix
        self.urlPathProvider = urlPathProvider
    }

    private func updateAttributes(input: OperationStackInput, attributes: Smithy.Context) throws {
        guard var urlPath = urlPathProvider(input) else {
           let message = "Creating the url path failed, a required property in the path was nil"
           throw HTTPClientError.pathCreationFailed(message)
        }
        if let urlPrefix = urlPrefix, !urlPrefix.isEmpty {
            urlPath = "\(urlPrefix)\(urlPath)"
        }
        attributes.path = urlPath
    }
}

extension URLPathMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeSerialization(context: some MutableInput<InputType>) async throws {
        // This is an interceptor and not a serializer because endpoints are used to resolve the host
        try updateAttributes(input: context.getInput(), attributes: context.getAttributes())
    }
}
