//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Component used by an Orchestrator to modify a request message with the endpoint
/// the request should be sent to.
public protocol ApplyEndpoint<RequestType, AttributesType> {

    /// The type of the request message.
    associatedtype RequestType: RequestMessage

    /// The type of the attributes the component requires.
    associatedtype AttributesType: HasAttributes

    /// Applies the endpoint to the request.
    /// - Parameters:
    ///   - request: The request.
    ///   - selectedAuthScheme: The auth scheme being used, if present.
    ///   - attributes: The attributes available.
    /// - Returns: The request with the endpoint applied.
    func apply(
        request: RequestType,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: AttributesType
    ) async throws -> RequestType
}

/// Concrete ApplyEndpoint backed by a closure.
internal struct WrappedApplyEndpoint<RequestType: RequestMessage, AttributesType: HasAttributes>: ApplyEndpoint {
    internal let closure: (RequestType, SelectedAuthScheme?, AttributesType) async throws -> RequestType

    public func apply(
        request: RequestType,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: AttributesType
    ) async throws -> RequestType {
        return try await self.closure(request, selectedAuthScheme, attributes)
    }
}
