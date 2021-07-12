/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public enum HttpBody {
    case data(Data?)
    case stream(ByteStream)
    case none
}

extension HttpBody: Equatable {
    public static func == (lhs: HttpBody, rhs: HttpBody) -> Bool {
        switch (lhs, rhs) {
        case (let .data(unwrappedlhsData), let .data(unwrappedRhsData)):
            return unwrappedlhsData == unwrappedRhsData
        case (let .stream(byteslhs), let .stream(bytesrhs)):
            return byteslhs.toBytes() === bytesrhs.toBytes()
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
            return AwsInputStream(stream.toBytes())
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
            bodyAsString = String(data: stream.toBytes().toData(), encoding: .utf8)
        default:
            bodyAsString = nil
        }
        return bodyAsString ?? ""
    }
}
