/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public enum HttpBody: Equatable {
    public static func == (lhs: HttpBody, rhs: HttpBody) -> Bool {
        fatalError()
    }
    
    case data(Data?)
    case stream(ByteStream)
    case none
    case asyncThrowingStream(AsyncThrowingStream<Data, Error>)
}

public protocol Channel {
    /// Reads up to `count` bytes from underlying data source.
    /// - Parameter count: The maximum number of bytes to read.
    /// - Returns: The data read from the underlying data source.
    /// `nil` if the end of the underlying data source is reached.
    /// `0` if no bytes are available before the underlying data source is closed.
    /// otherwise, the number of bytes read.
    func read(upToCount count: Int) async throws -> Data?

    /// Reads all bytes from the underlying data source.
    /// - Returns: The data read from the underlying data source.
    /// `nil` if the end of the underlying data source is reached.
    /// `0` if no bytes are available before the underlying data source is closed.
    /// otherwise, the number of bytes read.
    func readToEnd() async throws -> Data?
}

public class AsyncThrowingStreamChannel: Channel {
    let stream: AsyncThrowingStream<Data, Error>
    var buffer: Data = Data()

    public init(stream: AsyncThrowingStream<Data, Error>) {
        self.stream = stream
    }

    public func read(upToCount count: Int) async throws -> Data? {
        var data = Data()
        var remaining = count

        // copy anything leftover from the last read
        if !buffer.isEmpty {
           let bytesToCopy = min(remaining, buffer.count)
           data.append(buffer[0..<Int(bytesToCopy)])
           remaining -= bytesToCopy
           buffer = buffer[Int(bytesToCopy)..<buffer.count]
        }

        var iterator = stream.makeAsyncIterator()
        while remaining > 0 {
            let next = try await iterator.next()
            if let next = next {
                // copy remaining bytes from the next chunk
                let bytesToCopy = min(remaining, next.count)
                data.append(next[0..<Int(bytesToCopy)])
                remaining -= bytesToCopy

                // store leftover bytes for next read
                if next.count > remaining {
                    buffer = Data(next[bytesToCopy..<next.count])
                }
            } else {
                break
            }
        }
        
        return data
    }

    public func readToEnd() async throws -> Data? {
        fatalError()
    }
}


public extension HttpBody {
    static var empty: HttpBody {
        .data(nil)
    }

    func toBytes() -> ByteBuffer? {
        switch self {
        case let .data(data):
            return data.map(ByteBuffer.init(data:))
        case let .stream(stream):
            return stream.toBytes()
        case .none:
            return nil
        case .asyncThrowingStream(_):
            // return .init(data: .init())
            return nil
        }
    }

    func toStreamable() -> IStreamable {
        switch self {
        case .stream(let stream):
            switch stream {
            case .reader(let streamReader):
                guard let streamable = streamReader as? IStreamable else {
                    fatalError()
                }
                return streamable
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }

    /// Returns true if the http body is `.none` or if the underlying data is nil or is empty.
    var isEmpty: Bool {
        switch self {
        case let .data(data):
            return data?.isEmpty ?? true
        case let .stream(stream):
            fatalError()
        case .asyncThrowingStream(_):
            fatalError()
        case .none:
            return true
        }
    }
}

extension HttpBody: CustomDebugStringConvertible {
    public var debugDescription: String {
        var bodyAsString: String?
        switch self {
        case .data(let data):
            if let data = data {
                bodyAsString = String(data: data, encoding: .utf8)
            }
        case .stream(let stream):
            bodyAsString = String(data: stream.toBytes().getData(), encoding: .utf8)
        default:
            bodyAsString = nil
        }
        return bodyAsString ?? ""
    }
}
