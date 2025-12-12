//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension Shape {

    var structConsumerMethod: String {
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
            fatalError("Cannot serialize type \(type)")
        }
    }

    var structConsumerVarName: String {
        guard id.member == nil else { fatalError("Constructing struct consumer for a member") }
        let namespacePortion = id.namespace.replacingOccurrences(of: ".", with: "_")
        let namePortion = id.name
        return "structconsumer__\(namespacePortion)__\(namePortion)"
    }
}
