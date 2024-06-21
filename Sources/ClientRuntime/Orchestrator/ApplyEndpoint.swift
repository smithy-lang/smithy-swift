//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import protocol Smithy.RequestMessage
import struct SmithyHTTPAuthAPI.SelectedAuthScheme

/// Component used by an Orchestrator to modify a request message with the endpoint
/// the request should be sent to.
public protocol ApplyEndpoint<RequestType> {

    /// The type of the request message.
    associatedtype RequestType: RequestMessage

    /// Applies the endpoint to the request.
    /// - Parameters:
    ///   - request: The request.
    ///   - selectedAuthScheme: The auth scheme being used, if present.
    ///   - attributes: The attributes available.
    /// - Returns: The request with the endpoint applied.
    func apply(
        request: RequestType,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: Context
    ) async throws -> RequestType
}

/// Concrete ApplyEndpoint backed by a closure.
internal struct WrappedApplyEndpoint<RequestType: RequestMessage>: ApplyEndpoint {
    internal let closure: (RequestType, SelectedAuthScheme?, Context) async throws -> RequestType

    public func apply(
        request: RequestType,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: Context
    ) async throws -> RequestType {
        return try await self.closure(request, selectedAuthScheme, attributes)
    }
}
