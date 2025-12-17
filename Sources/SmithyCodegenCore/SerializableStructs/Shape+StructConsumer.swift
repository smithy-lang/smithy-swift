//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension Shape {

    var structConsumerMethod: String {
        get throws {
            switch type {
            case .blob:
                return "writeBlob"
            case .boolean:
                return "writeBoolean"
            case .string, .enum:
                return "writeString"
            case .timestamp:
                return "writeTimestamp"
            case .byte:
                return "writeByte"
            case .short:
                return "writeShort"
            case .integer, .intEnum:
                return "writeInteger"
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
                return "writeStruct"
            case .member, .service, .resource, .operation:
                throw ModelError("Cannot serialize type \(type)")
            }
        }
    }
}
