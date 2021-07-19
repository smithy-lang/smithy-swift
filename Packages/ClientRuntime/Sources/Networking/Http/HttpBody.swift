/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public enum HttpBody: Equatable {
    case data(Data?)
    case stream(ByteStream)
    case none
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
            guard let data = data else {
                return nil
            }
            return AwsInputStream(ByteBuffer(data: data))
        case .stream(let stream):
            switch stream {
            case .reader(let reader):
                return AwsInputStream(reader.byteBuffer)
            case .buffer(let byteBuffer):
                return AwsInputStream(byteBuffer)
            }
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
