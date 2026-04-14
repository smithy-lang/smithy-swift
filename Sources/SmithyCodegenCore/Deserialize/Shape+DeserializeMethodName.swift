//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID
import struct Smithy.StreamingTrait

extension Shape {

    var deserializeMethodName: String {
        get throws {
            switch type {
            case .blob:
                if hasTrait(StreamingTrait.self) {
                    return "readDataStream"
                } else {
                    return "readBlob"
                }
            case .boolean:
                return "readBoolean"
            case .string:
                return "readString"
            case .enum:
                return "readEnum"
            case .timestamp:
                return "readTimestamp"
            case .byte:
                return "readByte"
            case .short:
                return "readShort"
            case .integer:
                return "readInteger"
            case .intEnum:
                return "readIntEnum"
            case .long:
                return "readLong"
            case .float:
                return "readFloat"
            case .document:
                return "readDocument"
            case .double:
                return "readDouble"
            case .bigDecimal:
                return "readBigDecimal"
            case .bigInteger:
                return "readBigInteger"
            case .list, .set:
                return "readList"
            case .map:
                return "readMap"
            case .structure, .union:
                if hasTrait(StreamingTrait.self) {
                    return "readEventStream"
                } else {
                    return "readStruct"
                }
            case .member, .service, .resource, .operation:
                throw ModelError("Cannot serialize type \(type)")
            }
        }
    }
}
