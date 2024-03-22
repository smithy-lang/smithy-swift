//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The base type of all context objects passed to `Interceptor` methods.
public protocol InterceptorContext {

    /// The type of the transport message that will be transmitted by the operation being invoked.
    associatedtype RequestType

    /// The type of the transport message that will be received by the operation being invoked.
    associatedtype ResponseType

    /// The type of the attributes that will be available to all interceptors.
    associatedtype AttributesType: HasAttributes

    /// - Returns: The input for the operation being invoked.
    func getInput() -> Any

    /// - Returns: The attributes available in this interceptor context.
    func getAttributes() -> AttributesType
}

public extension InterceptorContext {
    /// Get the input for the operation being invoked as the type `T`.
    /// - Returns: The input as `T` if the input can be successfully cast to `T`.
    func getInput<T>() -> T? {
        self.getInput() as? T
    }
}

/// Context given to interceptor hooks called before request serialization.
public protocol BeforeSerialization<AttributesType>: InterceptorContext {}

/// Context given to interceptor hooks that can mutate the operation input.
public protocol MutableInput<AttributesType>: InterceptorContext {

    /// Mutates the operation input.
    /// - Parameter updated: The updated operation input.
    mutating func updateInput(updated: Any)
}

/// Context given to interceptor hooks called after request serialization.
/// 
/// These hooks have access to the serialized `RequestType`.
public protocol AfterSerialization<RequestType, AttributesType>: InterceptorContext {

    /// - Returns: The serialized request.
    func getRequest() -> RequestType
}

/// Context given to interceptor hooks that can mutate the serialized request.
///
/// These hooks have access to the serialized `RequestType`
public protocol MutableRequest<RequestType, AttributesType>: InterceptorContext {

    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// Mutates the serialized request.
    /// - Parameter updated: The updated request.
    mutating func updateRequest(updated: RequestType)
}

/// Context given to interceptor hooks called before response deserialization, after the response has been received.
/// 
/// These hooks have access to the serialized `RequestType` and `ResponseType`.
public protocol BeforeDeserialization<RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response.
    func getResponse() -> ResponseType
}

/// Context given to interceptor hooks that can mutate the serialized response.
///
/// These hooks have access to the serialized `RequestType` and `ResponseType`.
public protocol MutableResponse<RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response.
    func getResponse() -> ResponseType

    /// Mutates the serialized response.
    /// - Parameter updated: The updated response.
    mutating func updateResponse(updated: ResponseType)
}

/// Context given to interceptor hooks called after response deserialization.
/// 
/// These hooks have access to the serialized `RequestType` and `ResponseType`, as well as the operation output.
public protocol AfterDeserialization<RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response.
    func getResponse() -> ResponseType

    /// - Returns: The operation output.
    func getOutput() -> Any
}

/// Context given to interceptor hooks called after each attempt at sending the request.
/// 
/// These hooks have access to the serialized `RequestType` and `ResponseType` (if a response was received), as well as the operation output.
public protocol AfterAttempt<RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response, if one was received.
    func getResponse() -> ResponseType?

    /// - Returns: The operation output.
    func getOutput() -> Any
}

/// Context given to interceptor hooks that can mutate the operation output, called after each attempt at sending the request.
///
/// These hooks have access to the serialized `RequestType` and `ResponseType` (if a response was received), as well as the operation output.
public protocol MutableOutputAfterAttempt<RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response, if one was received.
    func getResponse() -> ResponseType?

    /// - Returns: The operation output.
    func getOutput() -> Any

    /// Mutates the operation output.
    /// - Parameter updated: The updated output.
    mutating func updateOutput(updated: Any)
}

/// Context given to interceptor hooks called after execution.
/// 
/// These hooks have access to the serialized `RequestType` (if it was successfully serialized) and the `ResponseType` 
/// (if a response was received), as well as the operation output.
public protocol Finalization<RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request, if available.
    func getRequest() -> RequestType?

    /// - Returns: The serialized response, if one was received.
    func getResponse() -> ResponseType?

    /// - Returns: The operation output.
    func getOutput() -> Any
}

/// Context given to interceptor hooks that can mutate the operation output, called after execution.
/// 
/// These hooks have access to the serialized `RequestType` (if it was successfully serialized) and the `ResponseType` 
/// (if a response was received), as well as the operation output.
public protocol MutableOutputFinalization<RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request, if available.
    func getRequest() -> RequestType?

    /// - Returns: The serialized response, if one was received.
    func getResponse() -> ResponseType?

    /// - Returns: The operation output.
    func getOutput() -> Any

    /// Mutates the operation output.
    /// - Parameter updated: The updated output.
    mutating func updateOutput(updated: Any)
}
