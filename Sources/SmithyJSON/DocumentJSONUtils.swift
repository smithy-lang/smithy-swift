//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import func CoreFoundation.CFGetTypeID
import func CoreFoundation.CFBooleanGetTypeID
import struct Foundation.Data
import struct Foundation.Date
import class Foundation.DateFormatter
import class Foundation.JSONSerialization
import struct Foundation.Locale
import class Foundation.NSNull
import class Foundation.NSNumber
@_spi(SmithyDocumentImpl) import Smithy

public extension DocumentContainer {

    static func make(from data: Data) throws -> DocumentContainer {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return try Self.make(from: jsonObject)
    }

    static func make(from jsonObject: Any) throws -> DocumentContainer {
        let doc: any Document
        if let object = jsonObject as? [String: Any] {
            doc = StringMapDocument(value: try object.mapValues { try Self.make(from: $0) })
        } else if let array = jsonObject as? [Any] {
            doc = ListDocument(value: try array.map { try Self.make(from: $0) })
        } else if let nsNumber = jsonObject as? NSNumber {
            // Check if the NSNumber is a boolean
            if CFGetTypeID(nsNumber) == CFBooleanGetTypeID() {
                doc = BooleanDocument(value: nsNumber.boolValue)
            } else {
                // Check numeric types
                let numberType = String(cString: nsNumber.objCType)
                switch numberType {
                case "c":  // char
                    doc = ByteDocument(value: nsNumber.int8Value)
                case "s":  // short
                    doc = ShortDocument(value: nsNumber.int16Value)
                case "i", "l":  // int, long
                    doc = IntegerDocument(value: nsNumber.intValue)
                case "q":  // long long
                    doc = LongDocument(value: nsNumber.int64Value)
                case "f":  // float
                    doc = FloatDocument(value: nsNumber.floatValue)
                case "d":  // double
                    doc = DoubleDocument(value: nsNumber.doubleValue)
                default:
                    throw DocumentError.invalidJSONData
                }
            }
        } else if let string = jsonObject as? String {
            doc = StringDocument(value: string)
        } else if let data = jsonObject as? Data {
            doc = BlobDocument(value: data)
        } else if let date = jsonObject as? Date {
            doc = TimestampDocument(value: date)
        } else if jsonObject is NSNull {
            doc = NullDocument()
        } else {
            throw DocumentError.invalidJSONData
        }
        return DocumentContainer(document: doc)
    }
}
