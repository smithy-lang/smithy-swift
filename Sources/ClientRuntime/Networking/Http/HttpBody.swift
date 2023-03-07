/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public enum HttpBody {
    case data(Data?)
    case stream(Stream)
    case none
}

extension HttpBody: Equatable {
    public static func == (lhs: HttpBody, rhs: HttpBody) -> Bool {
        switch (lhs, rhs) {
        case (.data(let lhsData), .data(let rhsData)):
            return lhsData == rhsData
        case (.stream(let lhsStream), .stream(let rhsStream)):
            return try! lhsStream.isEqual(to: rhsStream)
        default:
            return false
        }
    }
}

extension HttpBody {
    public init(byteStream: ByteStream) {
        switch byteStream {
        case .data(let data):
            self = .data(data)
        case .stream(let stream):
            self = .stream(stream)
        }
    }
}

public extension HttpBody {
    static var empty: HttpBody {
        .data(nil)
    }

    func toData() throws -> Data? {
        switch self {
        case .data(let data):
            return data
        case .stream(let stream):
            try stream.seek(toOffset: 0)
            return try stream.readToEnd()
        case .none:
            return nil
        }
    }

    /// Returns true if the http body is `.none` or if the underlying data is nil or is empty.
    var isEmpty: Bool {
        switch self {
        case let .data(data):
            return data?.isEmpty ?? true
        case let .stream(stream):
            return stream.isEmpty
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
            // reading a non-seekable stream will consume the stream
            // which will impact the ability to read the stream later
            // so we only read the stream if it is seekable
            if stream.isSeekable {
                let currentPosition = stream.position
                if let data = try? stream.readToEnd() {
                    bodyAsString = String(data: data, encoding: .utf8)
                }
                try? stream.seek(toOffset: currentPosition)
            } else {
                bodyAsString = """
                Position: \(stream.position)
                Length: \(stream.length ?? -1)
                IsEmpty: \(stream.isEmpty)
                IsSeekable: \(stream.isSeekable)
                """
            }
        default:
            bodyAsString = nil
        }
        return bodyAsString ?? ""
    }
}
