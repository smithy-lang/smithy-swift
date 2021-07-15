/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public enum HttpBody {
    case data(Data?)
    case stream(Reader)
    case none
}

extension HttpBody: Equatable {
    public static func == (lhs: HttpBody, rhs: HttpBody) -> Bool {
        switch (lhs, rhs) {
        case (let .data(unwrappedlhsData), let .data(unwrappedRhsData)):
            return unwrappedlhsData == unwrappedRhsData
        case (let .stream(byteslhs), let .stream(bytesrhs)):
            let streamLhs = byteslhs.readFrom()
            let streamRhs = bytesrhs.readFrom()
            return streamLhs.readRemaining(maxBytes: UInt(Int.max)) === streamRhs.readRemaining(maxBytes: UInt(Int.max))
        case (.none, .none):
            return true
        default:
            return false
        }
    }
}

public extension HttpBody {
    static var empty: HttpBody {
        .data(nil)
    }
}

extension HttpBody {
    func toAwsInputStream() -> AwsInputStream? {
        switch self {
        case .data(let data):
            if let data = data {
                return AwsInputStream(ByteBuffer(data: data))
            } else {
                return nil
            }
        case .stream(let stream):
            let reader = stream.readFrom()
            let streamSinkBodyStream = StreamSinkBodyStream(streamSink: reader)
            return AwsInputStream(streamSinkBodyStream)
        case .none:
            return nil
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
            let reader = stream.readFrom()
            bodyAsString = String(data: reader.readRemaining(maxBytes: UInt(Int.max)).toData(), encoding: .utf8)
        default:
            bodyAsString = nil
        }
        return bodyAsString ?? ""
    }
}
