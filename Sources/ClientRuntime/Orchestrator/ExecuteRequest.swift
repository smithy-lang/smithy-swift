//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Component used by an Orchestrator to send a request to the service and receive a response.
public protocol ExecuteRequest<RequestType, ResponseType, AttributesType> {
    
    /// The type of the request message.
    associatedtype RequestType: RequestMessage

    /// The type of the response message.
    associatedtype ResponseType: ResponseMessage

    /// The type of the attributes required by the component.
    associatedtype AttributesType: HasAttributes

    /// Sends the request and receives the response.
    /// - Parameters:
    ///   - request: The request to send.
    ///   - attributes: The attributes available.
    /// - Returns: The received response.
    func execute(request: RequestType, attributes: AttributesType) async throws -> ResponseType
}

/// Concrete ExecuteRequest backed by a closure.
internal struct WrappedExecuteRequest<
    RequestType: RequestMessage,
    ResponseType: ResponseMessage,
    AttributesType: HasAttributes
>: ExecuteRequest {
    internal let closure: (RequestType, AttributesType) async throws -> ResponseType

    public func execute(request: RequestType, attributes: AttributesType) async throws -> ResponseType {
        return try await closure(request, attributes)
    }
}
