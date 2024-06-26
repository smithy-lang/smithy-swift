//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import protocol Smithy.RequestMessage
import struct SmithyHTTPAuthAPI.SelectedAuthScheme

/// Component used by an Orchestrator to sign a request.
public protocol ApplySigner<RequestType> {

    /// The type of the request message.
    associatedtype RequestType: RequestMessage

    /// Applies the signer to the request.
    /// - Parameters:
    ///   - request: The request to sign.
    ///   - selectedAuthScheme: The auth scheme being used, if present.
    ///   - attributes: The attributes available.
    /// - Returns: The signed request.
    func apply(
        request: RequestType,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: Context
    ) async throws -> RequestType
}

/// Concrete ApplySigner backed by a closure.
internal struct WrappedApplySigner<RequestType: RequestMessage>: ApplySigner {
    internal let closure: (RequestType, SelectedAuthScheme?, Context) async throws -> RequestType

    public func apply(
        request: RequestType,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: Context
    ) async throws -> RequestType {
        return try await self.closure(request, selectedAuthScheme, attributes)
    }
}
