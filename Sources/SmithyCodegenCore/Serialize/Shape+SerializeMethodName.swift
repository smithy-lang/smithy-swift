//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.StreamingTrait

extension Shape {

    var serializeMethodName: String {
        get throws {
            switch type {
            case .blob:
                if hasTrait(StreamingTrait.self) {
                    return "writeDataStream"
                } else {
                    return "writeBlob"
                }
            case .boolean:
                return "writeBoolean"
            case .string:
                return "writeString"
            case .enum:
                return "writeEnum"
            case .timestamp:
                return "writeTimestamp"
            case .byte:
                return "writeByte"
            case .short:
                return "writeShort"
            case .integer:
                return "writeInteger"
            case .intEnum:
                return "writeIntEnum"
            case .long:
                return "writeLong"
            case .float:
                return "writeFloat"
            case .document:
                return "writeDocument"
            case .double:
                return "writeDouble"
            case .bigDecimal:
                return "writeBigDecimal"
            case .bigInteger:
                return "writeBigInteger"
            case .list, .set:
                return "writeList"
            case .map:
                return "writeMap"
            case .structure, .union:
                if hasTrait(StreamingTrait.self) {
                    return "writeEventStream"
                } else {
                    return "writeStruct"
                }
            case .member, .service, .resource, .operation:
                throw ModelError("Cannot serialize type \(type)")
            }
        }
    }
}
