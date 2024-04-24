//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The base type of all context objects passed to `Interceptor` methods.
public protocol InterceptorContext: AnyObject {

    /// The type of the modeled operation input.
    associatedtype InputType

    /// The type of the modeled operation output.
    associatedtype OutputType

    /// The type of the transport message that will be transmitted by the operation being invoked.
    associatedtype RequestType

    /// The type of the transport message that will be received by the operation being invoked.
    associatedtype ResponseType

    /// The type of the attributes that will be available to all interceptors.
    associatedtype AttributesType: HasAttributes

    /// - Returns: The input for the operation being invoked.
    func getInput() -> InputType

    /// - Returns: The attributes available in this interceptor context.
    func getAttributes() -> AttributesType
}

/// Context given to interceptor hooks called before request serialization.
public protocol BeforeSerialization<InputType, AttributesType>: InterceptorContext {}

/// Context given to interceptor hooks that can mutate the operation input.
public protocol MutableInput<InputType, AttributesType>: InterceptorContext {

    /// Mutates the operation input.
    /// - Parameter updated: The updated operation input.
    func updateInput(updated: InputType)
}

/// Context given to interceptor hooks called after request serialization.
///
/// These hooks have access to the serialized `RequestType`.
public protocol AfterSerialization<InputType, RequestType, AttributesType>: InterceptorContext {

    /// - Returns: The serialized request.
    func getRequest() -> RequestType
}

/// Context given to interceptor hooks that can mutate the serialized request.
///
/// These hooks have access to the serialized `RequestType`
public protocol MutableRequest<InputType, RequestType, AttributesType>: InterceptorContext {

    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// Mutates the serialized request.
    /// - Parameter updated: The updated request.
    func updateRequest(updated: RequestType)
}

/// Context given to interceptor hooks called before response deserialization, after the response has been received.
///
/// These hooks have access to the serialized `RequestType` and `ResponseType`.
public protocol BeforeDeserialization<InputType, RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response.
    func getResponse() -> ResponseType
}

/// Context given to interceptor hooks that can mutate the serialized response.
///
/// These hooks have access to the serialized `RequestType` and `ResponseType`.
public protocol MutableResponse<InputType, RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response.
    func getResponse() -> ResponseType

    /// Mutates the serialized response.
    /// - Parameter updated: The updated response.
    func updateResponse(updated: ResponseType)
}

/// Context given to interceptor hooks called after response deserialization.
///
/// These hooks have access to the serialized `RequestType` and `ResponseType`, as well as the operation output.
public protocol AfterDeserialization<InputType, OutputType, RequestType, ResponseType, AttributesType>:
    InterceptorContext {

    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response.
    func getResponse() -> ResponseType

    /// - Returns: The operation output.
    func getOutput() -> OutputType
}

/// Context given to interceptor hooks called after each attempt at sending the request.
///
/// These hooks have access to the serialized `RequestType` and `ResponseType` (if a response was received), as well as the operation output.
public protocol AfterAttempt<InputType, OutputType, RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response, if one was received.
    func getResponse() -> ResponseType?

    /// - Returns: The operation output.
    func getOutput() -> OutputType
}

/// Context given to interceptor hooks that can mutate the operation output, called after each attempt at sending the request.
///
/// These hooks have access to the serialized `RequestType` and `ResponseType` (if a response was received), as well as the operation output.
public protocol MutableOutputAfterAttempt<InputType, OutputType, RequestType, ResponseType, AttributesType>:
    InterceptorContext {

    /// - Returns: The serialized request.
    func getRequest() -> RequestType

    /// - Returns: The serialized response, if one was received.
    func getResponse() -> ResponseType?

    /// - Returns: The operation output.
    func getOutput() -> OutputType

    /// Mutates the operation output.
    /// - Parameter updated: The updated output.
    func updateOutput(updated: OutputType)
}

/// Context given to interceptor hooks called after execution.
///
/// These hooks have access to the serialized `RequestType` (if it was successfully serialized) and the `ResponseType`
/// (if a response was received), as well as the operation output.
public protocol Finalization<InputType, OutputType, RequestType, ResponseType, AttributesType>: InterceptorContext {
    /// - Returns: The serialized request, if available.
    func getRequest() -> RequestType?

    /// - Returns: The serialized response, if one was received.
    func getResponse() -> ResponseType?

    /// - Returns: The operation output.
    func getOutput() -> OutputType
}

/// Context given to interceptor hooks that can mutate the operation output, called after execution.
///
/// These hooks have access to the serialized `RequestType` (if it was successfully serialized) and the `ResponseType`
/// (if a response was received), as well as the operation output.
public protocol MutableOutputFinalization<InputType, OutputType, RequestType, ResponseType, AttributesType>:
    InterceptorContext {

    /// - Returns: The serialized request, if available.
    func getRequest() -> RequestType?

    /// - Returns: The serialized response, if one was received.
    func getResponse() -> ResponseType?

    /// - Returns: The operation output.
    func getOutput() -> OutputType

    /// Mutates the operation output.
    /// - Parameter updated: The updated output.
    func updateOutput(updated: OutputType)
}
