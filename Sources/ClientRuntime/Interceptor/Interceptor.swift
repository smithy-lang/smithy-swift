//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An interceptor allows injecting code into the SDK's request execution pipeline.
public protocol Interceptor<RequestType, ResponseType, AttributesType> {

    /// The type of the request transport messages sent by operations this interceptor can hook into.
    associatedtype RequestType: RequestMessage

    /// The type of the response transport message received by operations this interceptor can hook into.
    associatedtype ResponseType: ResponseMessage

    /// The type of the attributes that will be available to the interceptor.
    associatedtype AttributesType: HasAttributes

    /// A hook called at the start of execution, before the SDK does anything else.
    func readBeforeExecution(context: some BeforeSerialization<AttributesType>) async throws

    /// A hook called before the operation input is serialized into the transport message. This
    /// method has the ability to modify the operation input.
    func modifyBeforeSerialization(context: some MutableInput<AttributesType>) async throws

    /// A hook called before the operation input is serialized into the transport message.
    func readBeforeSerialization(context: some BeforeSerialization<AttributesType>) async throws

    /// A hook called after the operation input is serialized into the transport message.
    func readAfterSerialization(context: some AfterSerialization<RequestType, AttributesType>) async throws

    /// A hook called before the retry loop is entered. This method has the ability to modify the transport
    /// request message.
    func modifyBeforeRetryLoop(context: some MutableRequest<RequestType, AttributesType>) async throws

    /// A hook called before each attempt at sending the tranport request message to the service.
    func readBeforeAttempt(context: some AfterSerialization<RequestType, AttributesType>) async throws

    /// A hook called before the transport request message is signed. This method has the ability to modify
    /// the transport request message.
    func modifyBeforeSigning(context: some MutableRequest<RequestType, AttributesType>) async throws

    /// A hook called before the transport request message is signed.
    func readBeforeSigning(context: some AfterSerialization<RequestType, AttributesType>) async throws

    /// A hook called after the transport request message is signed.
    func readAfterSigning(context: some AfterSerialization<RequestType, AttributesType>) async throws

    /// A hook called before the transport request message is sent to the service. This method has the ability
    /// to modify the transport request message.
    func modifyBeforeTransmit(context: some MutableRequest<RequestType, AttributesType>) async throws

    /// A hook called before the transport request message is sent to the service.
    func readBeforeTransmit(context: some AfterSerialization<RequestType, AttributesType>) async throws

    /// A hook called after the transport request message is sent to the service, and a transport response
    /// message has been received.
    func readAfterTransmit(context: some BeforeDeserialization<RequestType, ResponseType, AttributesType>) async throws

    /// A hook called before the transport response message is deserialized. This method has the ability to
    /// modify the transport response message.
    func modifyBeforeDeserialization(
        context: some MutableResponse<RequestType, ResponseType, AttributesType>
    ) async throws

    /// A hook alled before the transport response message is deserialized.
    func readBeforeDeserialization(
        context: some BeforeDeserialization<RequestType, ResponseType, AttributesType>
    ) async throws

    /// A hook called after the transport response message is deserialized.
    func readAfterDeserialization(
        context: some AfterDeserialization<RequestType, ResponseType, AttributesType>
    ) async throws

    /// A hook called when an attempt is completed. This method has the ability to modify the operation output.
    func modifyBeforeAttemptCompletion(
        context: some MutableOutputAfterAttempt<RequestType, ResponseType, AttributesType>
    ) async throws

    /// A hook called when an attempt is completed.
    func readAfterAttempt(context: some AfterAttempt<RequestType, ResponseType, AttributesType>) async throws

    /// A hook called when execution is completed. This method has the ability to modify the operation output.
    func modifyBeforeCompletion(
        context: some MutableOutputFinalization<RequestType, ResponseType, AttributesType>
    ) async throws

    /// A hook called when execution is completed.
    func readAfterExecution(context: some Finalization<RequestType, ResponseType, AttributesType>) async throws
}

extension Interceptor {
    public func readBeforeExecution(context: some BeforeSerialization<AttributesType>) async throws {}

    public func modifyBeforeSerialization(context: some MutableInput<AttributesType>) async throws {}

    public func readBeforeSerialization(context: some BeforeSerialization<AttributesType>) async throws {}

    public func readAfterSerialization(context: some AfterSerialization<RequestType, AttributesType>) async throws {}

    public func modifyBeforeRetryLoop(context: some MutableRequest<RequestType, AttributesType>) async throws {}

    public func readBeforeAttempt(context: some AfterSerialization<RequestType, AttributesType>) async throws {}

    public func modifyBeforeSigning(context: some MutableRequest<RequestType, AttributesType>) async throws {}

    public func readBeforeSigning(context: some AfterSerialization<RequestType, AttributesType>) async throws {}

    public func readAfterSigning(context: some AfterSerialization<RequestType, AttributesType>) async throws {}

    public func modifyBeforeTransmit(context: some MutableRequest<RequestType, AttributesType>) async throws {}

    public func readBeforeTransmit(context: some AfterSerialization<RequestType, AttributesType>) async throws {}

    public func readAfterTransmit(
        context: some BeforeDeserialization<RequestType, ResponseType, AttributesType>
    ) async throws {}

    public func modifyBeforeDeserialization(
        context: some MutableResponse<RequestType, ResponseType, AttributesType>
    ) async throws {}

    public func readBeforeDeserialization(
        context: some BeforeDeserialization<RequestType, ResponseType, AttributesType>
    ) async throws {}

    public func readAfterDeserialization(
        context: some AfterDeserialization<RequestType, ResponseType, AttributesType>
    ) async throws {}

    public func modifyBeforeAttemptCompletion(
        context: some MutableOutputAfterAttempt<RequestType, ResponseType, AttributesType>
    ) async throws {}

    public func readAfterAttempt(context: some AfterAttempt<RequestType, ResponseType, AttributesType>) async throws {}

    public func modifyBeforeCompletion(
        context: some MutableOutputFinalization<RequestType, ResponseType, AttributesType>
    ) async throws {}

    public func readAfterExecution(context: some Finalization<RequestType, ResponseType, AttributesType>) async throws {
    }
}

extension Interceptor {
    func erase() -> AnyInterceptor<RequestType, ResponseType, AttributesType> {
        return AnyInterceptor(interceptor: self)
    }
}
