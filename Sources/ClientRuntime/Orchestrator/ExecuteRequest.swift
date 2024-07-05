//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import protocol Smithy.RequestMessage
import protocol Smithy.ResponseMessage

/// Component used by an Orchestrator to send a request to the service and receive a response.
public protocol ExecuteRequest<RequestType, ResponseType> {
    /// The type of the request message.
    associatedtype RequestType: RequestMessage

    /// The type of the response message.
    associatedtype ResponseType: ResponseMessage

    /// Sends the request and receives the response.
    /// - Parameters:
    ///   - request: The request to send.
    ///   - attributes: The attributes available.
    /// - Returns: The received response.
    func execute(request: RequestType, attributes: Context) async throws -> ResponseType
}

/// Concrete ExecuteRequest backed by a closure.
internal struct WrappedExecuteRequest<
    RequestType: RequestMessage,
    ResponseType: ResponseMessage
>: ExecuteRequest {
    internal let closure: (RequestType, Context) async throws -> ResponseType

    public func execute(request: RequestType, attributes: Context) async throws -> ResponseType {
        return try await closure(request, attributes)
    }
}
