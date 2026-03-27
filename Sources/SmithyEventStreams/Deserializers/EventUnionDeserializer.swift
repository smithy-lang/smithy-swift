//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import enum Smithy.ClientError
import struct Smithy.Document
import struct Smithy.Schema
import struct SmithyEventStreamsAPI.Message
import protocol SmithySerialization.Codec
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeDeserializer

/// A deserializer that is used to deserialize an event stream message to an event stream union.
///
/// Only use this deserializer for event stream unions.  Deserializing any other type will result in a
/// "not implemented" error.
///
/// When the message deserializes to an event, the event is returned to the caller.  If an exception
/// or error is passed on the event stream, those are thrown back to the caller.
struct EventUnionDeserializer: ShapeDeserializer {
    let codec: any Codec
    let message: Message

    func readStruct<T>(_ schema: Schema, _ value: inout T) throws where T: DeserializableStruct {
        switch try message.type() {
        case .event(let eventParams):
            // Locate the streaming union's member for this event, by matching member name to message type.
            guard let member = schema.members.first(where: { $0.id.member == eventParams.eventType }) else {

                // If no member matches the event, then read a sdkUnknown() value & return
                let message = "error processing event stream, unrecognized event: \(eventParams.eventType)"
                let sdkUnknownDeserializer = SDKUnknownDeserializer(string: message)
                let member = Schema(id: .init(id: schema.id, member: "sdkUnknown"), type: .string)
                try T.readConsumer(member, &value, sdkUnknownDeserializer)
                return
            }

            // Create an eventContentDeserializer to deserialize the event content,
            let eventContentDeserializer = EventContentDeserializer(codec: codec, message: message)

            // Deserialize using the event's member & the event content deserializer.
            try T.readConsumer(member, &value, eventContentDeserializer)
        case .exception(let exceptionParams):
            // Locate the streaming union's member for this exception, by matching member name to message type.
            guard let member = schema.members.first(where: { $0.id.member == exceptionParams.exceptionType }) else {
                let message = "unrecognized event stream exception type: \(exceptionParams.exceptionType)"
                throw ClientError.unknownError(message)
            }

            // Create an eventContentDeserializer to deserialize the exception content,
            let eventContentDeserializer = EventContentDeserializer(codec: codec, message: message)

            // Deserialize using the event's member & the event content deserializer.
            // The exception will be thrown back to the caller by the read consumer rather than returned.
            try T.readConsumer(member, &value, eventContentDeserializer)
        case .error(let errorParams):
            let code = errorParams.errorCode
            let errorMessage = errorParams.message ?? "nil"
            let message = "error processing event stream, ':error-code': \(code); message: \(errorMessage)"
            throw ClientError.unknownError(message)
        case .unknown(let messageType):
            throw ClientError.unknownError("unrecognized event stream message ':message-type': \(messageType)")
        }
    }

    func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        throw notImplemented
    }

    func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        throw notImplemented
    }

    func readBoolean(_ schema: Schema) throws -> Bool {
        throw notImplemented
    }

    func readBlob(_ schema: Schema) throws -> Data {
        throw notImplemented
    }

    func readByte(_ schema: Schema) throws -> Int8 {
        throw notImplemented
    }

    func readShort(_ schema: Schema) throws -> Int16 {
        throw notImplemented
    }

    func readInteger(_ schema: Schema) throws -> Int {
        throw notImplemented
    }

    func readLong(_ schema: Schema) throws -> Int {
        throw notImplemented
    }

    func readFloat(_ schema: Schema) throws -> Float {
        throw notImplemented
    }

    func readDouble(_ schema: Schema) throws -> Double {
        throw notImplemented
    }

    func readBigInteger(_ schema: Schema) throws -> Int64 {
        throw notImplemented
    }

    func readBigDecimal(_ schema: Schema) throws -> Double {
        throw notImplemented
    }

    func readString(_ schema: Schema) throws -> String {
        throw notImplemented
    }

    func readDocument(_ schema: Schema) throws -> Document {
        throw notImplemented
    }

    func readTimestamp(_ schema: Schema) throws -> Date {
        throw notImplemented
    }

    func readNull<T>(_ schema: Schema) throws -> T? {
        throw notImplemented
    }

    func isNull() throws -> Bool {
        throw notImplemented
    }

    var containerSize: Int { -1 }

    private var notImplemented: SerializerError { .init("Not implemented") }
}
