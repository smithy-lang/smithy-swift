/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public enum HttpBody: Equatable {
    case data(Data?)
    case stream(ByteStream)
    case none
    case channel(ChannelContent)
}

public struct ChannelContent: Equatable, IStreamable {
    public func seek(offset: Int64, streamSeekType: AwsCommonRuntimeKit.StreamSeekType) throws {
        fatalError()
    }
    
    public func read(buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int? {
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
        case .channel(_):
            fatalError()
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
        case .channel(_):
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
