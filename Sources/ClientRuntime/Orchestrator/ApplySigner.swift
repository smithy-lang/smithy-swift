//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Component used by an Orchestrator to sign a request.
public protocol ApplySigner<RequestType, AttributesType> {

    /// The type of the request message.
    associatedtype RequestType: RequestMessage

    /// The type of the attributes the component requires.
    associatedtype AttributesType: HasAttributes

    /// Applies the signer to the request.
    /// - Parameters:
    ///   - request: The request to sign.
    ///   - selectedAuthScheme: The auth scheme being used, if present.
    ///   - attributes: The attributes available.
    /// - Returns: The signed request.
    func apply(
        request: RequestType,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: AttributesType
    ) async throws -> RequestType
}

/// Concrete ApplySigner backed by a closure.
internal struct WrappedApplySigner<RequestType: RequestMessage, AttributesType: HasAttributes>: ApplySigner {
    internal let closure: (RequestType, SelectedAuthScheme?, AttributesType) async throws -> RequestType

    public func apply(
        request: RequestType,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: AttributesType
    ) async throws -> RequestType {
        return try await self.closure(request, selectedAuthScheme, attributes)
    }
}
