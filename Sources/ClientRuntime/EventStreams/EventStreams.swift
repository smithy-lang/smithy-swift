//
//  File.swift
//
//
//  Created by Jangir, Ganesh on 1/26/23.
//

import AwsCommonRuntimeKit
import Foundation.NSUUID

public func cannonicalString(date: Date, priorSignature: String, nonSignatureHeaders: String, payload: Data, region: String, service: String) throws -> String {
    // format YYYYMMDDTHHMMSSZ
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
    if #available(macOS 13, *) {
        dateFormatter.timeZone = .gmt
    } else {
        // Fallback on earlier versions
    }
    let datetime = dateFormatter.string(from: date)

    let dateFormatter2 = DateFormatter()
    dateFormatter2.dateFormat = "yyyyMMdd"
    if #available(macOS 13, *) {
        dateFormatter2.timeZone = .gmt
    } else {
        // Fallback on earlier versions
    }
    let dateOnly = dateFormatter2.string(from: date)
    
    let str = "AWS4-HMAC-SHA256-PAYLOAD\n\(datetime)Z\n\(dateOnly)/\(region)/\(service)/aws4_request\n\(priorSignature)\n\(nonSignatureHeaders)\n\(try payload.sha256().encodeToHexString())"
    
    print(str)
    
    return str
}

public func nonSignatureHeaders(date: Date) throws -> String{

    var bytes = Data(repeating: 0, count: 15)
    let name = ":date".data(using: .utf8)
    var offset = 0
    // size
    bytes[offset] = UInt8(name!.count)
    offset += 1
    
    // copy name to bytes
    for byte in name! {
        bytes[offset] = byte
        offset += 1
    }

    // copy type to bytes ie 8
    bytes[offset] = 8
    offset += 1

    // copy epoch milliseconds to bytes with big endian
    let epoch = date.millisecondsSince1970
    for i in stride(from: 7, through: 0, by: -1) {
        bytes[offset] = UInt8((epoch >> (i * 8)) & 0xff)
        offset += 1
    }
    return try bytes.sha256().encodeToHexString()
}

public struct EventStreams {
    
}

extension String {
    public var hexaData: Data { .init(hexa) }
    public var hexaBytes: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

extension Date {
    public var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

//    public init(millisecondsSince1970: Int64) {
//        self = Date(timeIntervalSince1970: TimeInterval(millisecondsSince1970) / 1000)
//    }
}

extension EventStreams {
    public typealias DecoderContinuation = CheckedContinuation<EventStreams.Message, Error>

    public struct Message: SignableMessage, CustomDebugStringConvertible, MessageDecoder, MessageEncoder {

        var continuation: DecoderContinuation? = nil

        public init(data: Data) async throws {
            var decoder: EventStreamMessageDecoder! = nil
            self = try await withCheckedThrowingContinuation { continuation in
                var decodedPayload = Data()
                var decodededHeaders: [EventStreamHeader] = []
                decoder = EventStreamMessageDecoder(
                    onPayloadSegment: { payload, finalSegment in
                        print("Message: onPayloadSegment")
                        decodedPayload.append(payload)
                    },
                    onPreludeReceived: { totalLength, headersLength in
                        print("Message: onPreludeReceived")
                    },
                    onHeaderReceived: { header in
                        print("Message: onHeaderReceived")
                        decodededHeaders.append(header)
                    },
                    onComplete: {
                        print("Message: onComplete")
                        let crtMessage = EventStreams.Message(headers: decodededHeaders.toHeaders(), payload: decodedPayload)
                        print(crtMessage)
                        continuation.resume(returning: crtMessage)
                    },
                    onError: { code, message in
                        print("Message: onError")
                        continuation.resume(throwing: EventStreamError.decoding(code, message))
                    })
                do {
                    try decoder.decode(data: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        public func decode(data: Data) async throws -> EventStreams.Message {
            fatalError()
        }
        
        public func encode(message: EventStreams.Message) throws -> Data {
            fatalError()
        }
        
        public func encode() throws -> Data {
            let crtMessage = self.toCRTMessage()
            return try crtMessage.getEncoded()
        }
        
        static let preludeLength: UInt = 8
        static let preludeLenghtWithCRC: UInt = preludeLength + 4
        
        public var headers: [EventStreams.Header]
        public let payload: Data
        
        public init(headers: [EventStreams.Header], payload: Data) {
            self.headers = headers
            self.payload = payload
        }
        
        public var debugDescription: String {
            "headers: \(headers), payload: \(String(data: payload, encoding: .utf8))"
        }
    }
}

extension EventStreams.Header {
    public func encode() -> Data {
        let nameBytes = name.data(using: .utf8)!
        fatalError()
    }
}

extension EventStreams {
    public struct Header {
        public let name: String
        public let value: HeaderValue
        
        public init(name: String, value: HeaderValue) {
            self.name = name
            self.value = value
        }
        
        public func toCRTHeader() -> EventStreamHeader {
            EventStreamHeader(name: name, value: value.toCRTHeaderValue())
        }
    }
}

extension EventStreams {
    public enum HeaderValue {
        case bool(Bool)
        case byte(Int8)
        case int16(Int16)
        case int32(Int32)
        case int64(Int64)
        case byteBuffer(Data)
        case string(String)
        case timestamp(Date)
        case uuid(UUID)
        
        public func toCRTHeaderValue() -> EventStreamHeaderValue {
            switch self {
            case .bool(let value):
                return .bool(value: value)
            case .byte(let value):
                return .byte(value: value)
            case .int16(let value):
                return .int16(value: value)
            case .int32(let value):
                return .int32(value: value)
            case .int64(let value):
                return .int64(value: value)
            case .byteBuffer(let value):
                return .byteBuf(value: value)
            case .string(let value):
                return .string(value: value)
            case .timestamp(let value):
                return .timestamp(value: value)
            case .uuid(let value):
                return .uuid(value: value)
            }
        }

        public func encode() -> Data {
            fatalError()
        }
    }
}

extension EventStreams {
    public enum MessageType {
        case event(EventParameters)
        case exception(ExceptionParameters)
        case error(ErrorParameters)
        
        public struct EventParameters {
            public let eventType: String
            public let contentType: String?
        }
        
        public struct ExceptionParameters {
            public let exceptionType: String
            public let contentType: String?
        }
        
        public struct ErrorParameters {
            public let errorCode: String
            public let message: String?
        }
    }
}


extension EventStreams.Message {
    public var type: EventStreams.MessageType {
        let headersByName = Dictionary(grouping: headers, by: { $0.name })
        // look for messageType header
        guard let messageTypeHeader = headersByName[":message-type"]?.first,
              case let .string(messageType) = messageTypeHeader.value else {
            fatalError()
        }
        
        switch messageType {
        case "event":
            guard let eventTypeHeader = headersByName[":event-type"]?.first, case let .string(eventType) = eventTypeHeader.value else {
                fatalError()
            }
            
            guard let contentTypeHeader = headersByName[":content-type"]?.first, case let .string(contentType) = contentTypeHeader.value else {
                fatalError()
            }
            return .event(.init(eventType: eventType, contentType: contentType))
        case "exception":
            guard let exceptionTypeHeader = headersByName[":exception-type"]?.first, case let .string(exceptionType) = exceptionTypeHeader.value else {
                fatalError()
            }
            guard let contentTypeHeader = headersByName[":content-type"]?.first, case let .string(contentType) = contentTypeHeader.value else {
                fatalError()
            }
            return .exception(.init(exceptionType: exceptionType, contentType: contentType))
        case "error":
            guard let errorCodeHeader = headersByName[":error-code"]?.first, case let
                .string(errorCode) = errorCodeHeader.value else {
                fatalError()
            }
            guard let messageHeader = headersByName[":error-message"]?.first, case let .string(message) = messageHeader.value else {
                fatalError()
            }
            return .error(.init(errorCode: errorCode, message: message))
        default:
            fatalError()
        }
    }
}

public protocol MessageDecoder {
    init(data: Data) async throws
    func decode(data: Data) async throws -> EventStreams.Message
}

public protocol MessageEncoder {
    func encode() throws -> Data
    func encode(message: EventStreams.Message) throws -> Data
}

public protocol MessageMarshaller {
    func marshall(encoder: RequestEncoder) throws -> EventStreams.Message
}

public  protocol MessageUnmarshaller {
    init(message: EventStreams.Message, decoder: ResponseDecoder) throws
}

public protocol SignableMessage {
    var headers: [EventStreams.Header] { get }
    var payload: Data { get }
}

public protocol MessageSigner {
    func sign(message: SignableMessage, previousSignature: String) async throws -> String
}

public struct AsyncRequestStream<Element>: AsyncSequence, Equatable {
    public static func == (lhs: AsyncRequestStream<Element>, rhs: AsyncRequestStream<Element>) -> Bool {
        false
    }
    
    public typealias Element = Element where Element : Equatable
    
    internal let stream: AsyncThrowingStream<Element, Error>
    
    public init(_ stream: AsyncThrowingStream<Element, Error>) {
        self.stream = stream
    }
    
    public func makeAsyncIterator() -> Iterator {
        return AsyncIterator(iterator: stream.makeAsyncIterator())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        var iterator: AsyncThrowingStream<Element, Error>.Iterator
        
        init(iterator: AsyncThrowingStream<Element, Error>.Iterator) {
            self.iterator = iterator
        }
        
        mutating public func next() async throws -> Element? {
            let element = try await iterator.next()
            return element
        }
    }
}

public struct AsyncResponseStream<Element>: AsyncSequence, Equatable {
    public static func == (lhs: AsyncResponseStream<Element>, rhs: AsyncResponseStream<Element>) -> Bool {
        false
    }
    
    public typealias Element = Element
    
    internal let stream: AsyncThrowingStream<Element, Error>
    
    public init(_ stream: AsyncThrowingStream<Element, Error>) {
        self.stream = stream
    }
    
    public func makeAsyncIterator() -> Iterator {
        return AsyncIterator(iterator: stream.makeAsyncIterator())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        var iterator: AsyncThrowingStream<Element, Error>.Iterator
        
        init(iterator: AsyncThrowingStream<Element, Error>.Iterator) {
            self.iterator = iterator
        }
        
        mutating public func next() async throws -> Element? {
            return try await iterator.next()
        }
    }
}

public enum EventStreamError: Error {
    case decoding(Int32, String)
}

public struct AWSMessageEncoder  {
//    public init() {}
//
//    public func encode(message: EventStreams.Message) throws -> ClientRuntime.Data {
//        let crtMessage = message.toCRTMessage()
//        return try crtMessage.getEncoded()
//    }
}

public struct AWSMessageDecoder {
//    public init(data: Data) async throws {
//        fatalError()
//    }
//
    static let messageLengthBytesCount: UInt = 4
//
//    public init() {}
//
//    public func decode(data: ClientRuntime.Data) async throws -> EventStreams.Message {
//        return try await withCheckedThrowingContinuation { continuation in
//            let decoder: EventStreamMessageDecoder
//            do {
//                var decodedPayload = Data()
//                var headers: [EventStreamHeader] = []
//                decoder = EventStreamMessageDecoder(
//                    onPayloadSegment: { payload, finalSegment in
//                        decodedPayload.append(payload)
//                    },
//                    onPreludeReceived: { totalLength, headersLength in
//
//                    },
//                    onHeaderReceived: { header in
//                        headers.append(header)
//                    },
//                    onComplete: {
//                        let crtMessage = EventStreams.Message(headers: headers.toHeaders(), payload: decodedPayload)
//                        print(crtMessage)
//                        continuation.resume(returning: crtMessage)
//                        print("onComplete")
//                    },
//                    onError: { code, message in
////                        completion(.failure(EventStreamError.decoding(code, message)))
//                        continuation.resume(throwing: EventStreamError.decoding(code, message))
//                        print("onError")
//                    })
//                try decoder.decode(data: data)
//            } catch {
//                continuation.resume(throwing: error)
//            }
//        }
//    }
//
//    public func decoder(completion: @escaping (Result<EventStreams.Message, EventStreamError>) -> Void) throws -> EventStreamMessageDecoder {
//        var decodedPayload = Data()
//        var headers: [EventStreamHeader] = []
//        let decoder = EventStreamMessageDecoder(
//            onPayloadSegment: { payload, finalSegment in
//                decodedPayload.append(payload)
//            },
//            onPreludeReceived: { totalLength, headersLength in
//
//            },
//            onHeaderReceived: { header in
//                headers.append(header)
//            },
//            onComplete: {
//                let crtMessage = EventStreams.Message(headers: headers.toHeaders(), payload: decodedPayload)
//                print(crtMessage)
//                completion(.success(crtMessage))
//                print("onComplete")
//            },
//            onError: { code, message in
//                completion(.failure(EventStreamError.decoding(code, message)))
////                contiuation.resume(throwing: EventStreamError.decoding(code, message))
//                print("onError")
//            })
//        return decoder
//    }
    
    public static func readMessage(streamReader: StreamReader) -> Data {
        let messageLengthBuffer = streamReader.read(maxBytes: messageLengthBytesCount, rewind: true).getData()
        let messageLength = messageLengthBuffer.reduce(0) { v, byte in
            return v << 8 | UInt(byte)
        }
        let messageBuffer = streamReader.read(maxBytes: messageLength, rewind: false).getData()
        return messageLengthBuffer + messageBuffer
    }
}

extension EventStreams.Message {
    func toCRTMessage() -> EventStreamMessage {
        let crtHeaders = headers.sorted(by: { h1, h2 in
            h1.name < h2.name
        }).map { header in
            header.toCRTHeader()
        }
        return EventStreamMessage(headers: crtHeaders, payload: payload)
    }
}

extension [EventStreamHeader] {
    func toHeaders() -> [EventStreams.Header] {
        self.map {
            $0.toHeader()
        }
    }
}

extension EventStreamHeader {
    func toHeader() -> EventStreams.Header {
        switch self.value {
        case .bool(value: let value):
            return .init(name: name, value: .bool(value))
        case .byte(value: let value):
            return .init(name: name, value: .byte(value))
        case .int16(value: let value):
            return .init(name: name, value: .int16(value))
        case .int32(value: let value):
            return .init(name: name, value: .int32(value))
        case .int64(value: let value):
            return .init(name: name, value: .int64(value))
        case .byteBuf(value: let value):
            return .init(name: name, value: .byteBuffer(value))
        case .string(value: let value):
            return .init(name: name, value: .string(value))
        case .timestamp(value: let value):
            return .init(name: name, value: .timestamp(value))
        case .uuid(value: let value):
            return .init(name: name, value: .uuid(value))
        }
    }
}

extension AsyncStream {
    public func customMap<Transformed>(_ transform: @escaping (Self.Element) -> Transformed) -> AsyncStream<Transformed> {
        return AsyncStream<Transformed> { continuation in
            Task {
                for await element in self {
                    continuation.yield(transform(element))
                }
                continuation.finish()
            }
        }
    }
    
    public func customMap<Transformed>(_ transform: @escaping (Self.Element) async -> Transformed) -> AsyncStream<Transformed> {
        return AsyncStream<Transformed> { continuation in
            Task {
                for await element in self {
                    continuation.yield(await transform(element))
                }
                continuation.finish()
            }
        }
    }
}

public struct ResponseStream: AsyncSequence {
    public typealias AsyncIterator = Iterator
    
    public typealias Element = EventStreams.Message

    public let stream: AsyncThrowingStream<EventStreams.Message, Error>
    
    public init(streamReader: StreamReader) {
        stream = AsyncThrowingStream<EventStreams.Message, Error> { continuation in
            Task {
                var decodedPayload = Data()
                var decodededHeaders: [EventStreamHeader] = []
                
                let decoder = EventStreamMessageDecoder(
                    onPayloadSegment: { payload, finalSegment in
//                        print("Message: onPayloadSegment")
                        decodedPayload.append(payload)
                    },
                    onPreludeReceived: { totalLength, headersLength in
//                        print("Message: onPreludeReceived")
                        decodedPayload = Data()
                        decodededHeaders = []
                    },
                    onHeaderReceived: { header in
//                        print("Message: onHeaderReceived")
                        decodededHeaders.append(header)
                    },
                    onComplete: {
//                        print("Message: onComplete")
                        let message = EventStreams.Message(headers: decodededHeaders.toHeaders(), payload: decodedPayload)
//                        print(message)
                        continuation.yield(message)
                    },
                    onError: { code, message in
//                        print("Message: onError")
                        continuation.finish(throwing: EventStreamError.decoding(code, message))
                    })
                
                while true {
                    let data = streamReader.read(maxBytes: 1024, rewind: true)
                    try decoder.decode(data: data.getData())
                }
                continuation.finish()
            }
        }
    }
    
//    public init(data: Data) async throws {
//        var decoder: EventStreamMessageDecoder! = nil
//        self = try await withCheckedThrowingContinuation { continuation in
//            var decodedPayload = Data()
//            var decodededHeaders: [EventStreamHeader] = []
//            decoder = EventStreamMessageDecoder(
//                onPayloadSegment: { payload, finalSegment in
//                    print("Message: onPayloadSegment")
//                    decodedPayload.append(payload)
//                },
//                onPreludeReceived: { totalLength, headersLength in
//                    print("Message: onPreludeReceived")
//                },
//                onHeaderReceived: { header in
//                    print("Message: onHeaderReceived")
//                    decodededHeaders.append(header)
//                },
//                onComplete: {
//                    print("Message: onComplete")
//                    let crtMessage = EventStreams.Message(headers: decodededHeaders.toHeaders(), payload: decodedPayload)
//                    print(crtMessage)
//                    continuation.resume(returning: crtMessage)
//                },
//                onError: { code, message in
//                    print("Message: onError")
//                    continuation.resume(throwing: EventStreamError.decoding(code, message))
//                })
//            do {
//                try decoder.decode(data: data)
//            } catch {
//                continuation.resume(throwing: error)
//            }
//        }
//    }
    
    public func makeAsyncIterator() -> Iterator {
        return AsyncIterator(iterator: self.stream.makeAsyncIterator())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        var iterator: AsyncThrowingStream<EventStreams.Message, Error>.Iterator
        
        init(iterator: AsyncThrowingStream<EventStreams.Message, Error>.Iterator) {
            self.iterator = iterator
        }
        
        mutating public func next() async throws -> EventStreams.Message? {
            return try await iterator.next()
        }
    }
}
