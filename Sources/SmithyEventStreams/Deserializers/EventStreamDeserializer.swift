//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.Date
import struct Smithy.Document
import protocol Smithy.ResponseMessage
import struct Smithy.Schema
import struct Smithy.StreamingTrait
import typealias SmithyEventStreamsAPI.UnmarshalClosure
import protocol SmithySerialization.Codec
import protocol SmithySerialization.DeserializableStruct
import struct SmithySerialization.SerializerError
import protocol SmithySerialization.ShapeDeserializer

/// A deserializer that may be used to deserialize an event stream from a response.
///
/// This deserializer should only be used on an output structure.  It will only deserialize the
/// event stream on the output, nothing else.  If the output structure has no event stream
/// member, it will throw an error.
/// It will throw a "not implemented" error if deserialization of any other type is attempted.
public struct EventStreamDeserializer: ShapeDeserializer {
    let codec: any Codec
    let response: ResponseMessage

    public init(codec: any Codec, response: ResponseMessage) {
        self.codec = codec
        self.response = response
    }

    public func readStruct<T: DeserializableStruct>(_ schema: Schema, _ value: inout T) throws {

        // Locate the event stream member on this structure.
        guard let member = schema.members.first(where: { $0.type == .union && $0.hasTrait(StreamingTrait.self) }) else {
            throw SerializerError("Streaming response received but no event streaming member")
        }

        // Call the read consumer with the streaming member and this same deserializer.
        // The readEventStream method immediately below will be called to deserialize the event stream.
        try T.readConsumer(member, &value, self)
    }

    public func readEventStream<E: DeserializableStruct>(_ schema: Schema) throws -> AsyncThrowingStream<E, any Error> {
        // Get the ReadableStream carrying the event stream data
        guard case .stream(let stream) = response.body else {
            throw SerializerError("Not a streaming body")
        }

        // An unmarshal closure is created that uses the EventTypeDeserializer to unmarshal each event
        // on the stream.  This lets us use schema-based serialization with the existing
        // marshal/unmarshal interface.
        let unmarshalClosure: UnmarshalClosure<E> = { [codec] message in
            let eventUnionDeserializer = EventUnionDeserializer(codec: codec, message: message)
            return try E.deserialize(eventUnionDeserializer)
        }

        // Create a message decoder stream & use that to create the async stream that is returned.
        return DefaultMessageDecoderStream<E>(
            stream: stream,
            messageDecoder: DefaultMessageDecoder(),
            unmarshalClosure: unmarshalClosure
        ).toAsyncStream()
    }

    public func readList<E>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> E) throws -> [E] {
        throw notImplemented
    }

    public func readMap<V>(_ schema: Schema, _ consumer: (any ShapeDeserializer) throws -> V) throws -> [String: V] {
        throw notImplemented
    }

    public func readBoolean(_ schema: Schema) throws -> Bool {
        throw notImplemented
    }

    public func readBlob(_ schema: Schema) throws -> Data {
        throw notImplemented
    }

    public func readByte(_ schema: Schema) throws -> Int8 {
        throw notImplemented
    }

    public func readShort(_ schema: Schema) throws -> Int16 {
        throw notImplemented
    }

    public func readInteger(_ schema: Schema) throws -> Int {
        throw notImplemented
    }

    public func readLong(_ schema: Schema) throws -> Int {
        throw notImplemented
    }

    public func readFloat(_ schema: Schema) throws -> Float {
        throw notImplemented
    }

    public func readDouble(_ schema: Schema) throws -> Double {
        throw notImplemented
    }

    public func readBigInteger(_ schema: Schema) throws -> Int64 {
        throw notImplemented
    }

    public func readBigDecimal(_ schema: Schema) throws -> Double {
        throw notImplemented
    }

    public func readString(_ schema: Schema) throws -> String {
        throw notImplemented
    }

    public func readDocument(_ schema: Schema) throws -> Document {
        throw notImplemented
    }

    public func readTimestamp(_ schema: Schema) throws -> Date {
        throw notImplemented
    }

    public func readNull<T>(_ schema: Schema) throws -> T? {
        throw notImplemented
    }

    public func isNull() throws -> Bool {
        throw notImplemented
    }

    public var containerSize: Int { -1 }

    private var notImplemented: SerializerError { .init("Not implemented") }
}
