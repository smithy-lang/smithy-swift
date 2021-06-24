/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public enum HttpBody {
    case data(Data?)
    case streamSource(StreamSourceProvider)
    case streamSink(StreamSinkProvider)
    case none
}

extension HttpBody: Equatable {
    public static func == (lhs: HttpBody, rhs: HttpBody) -> Bool {
        switch (lhs, rhs) {
        case (let .data(unwrappedlhsData), let .data(unwrappedRhsData)):
            return unwrappedlhsData == unwrappedRhsData
        case (.streamSource, .streamSource):
            return false
        case (.streamSink, .streamSink):
            return false
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

extension HttpBody: CustomDebugStringConvertible {
    public var debugDescription: String {
        var bodyAsString: String?
        switch self {
        case .data(let data):
            if let data = data {
                bodyAsString = String(data: data, encoding: .utf8)
            }
        case .streamSource(let stream):
            let byteBuffer = ByteBuffer(size: 1024)
            stream.unwrap().sendData(writeTo: byteBuffer)
            bodyAsString = String(data: byteBuffer.toData(), encoding: .utf8)
        default:
            bodyAsString = nil
        }
        return bodyAsString ?? ""
    }
}
