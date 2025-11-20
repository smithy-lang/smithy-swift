//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import func CoreFoundation.CFBooleanGetTypeID
import func CoreFoundation.CFGetTypeID
import struct Foundation.Data
import struct Foundation.Date
import class Foundation.DateFormatter
import class Foundation.JSONSerialization
import struct Foundation.Locale
import class Foundation.NSNull
import class Foundation.NSNumber
@_spi(SmithyDocumentImpl) import Smithy

public extension Document {

    static func make(from data: Data) throws -> Document {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return try Self.make(from: jsonObject)
    }

    /// Creates a Smithy `Document` from a Swift JSON object.
    ///
    /// The JSON object should obey the following:
    /// - The top level object is an NSArray or NSDictionary.
    /// - All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
    /// - All dictionary keys are instances of NSString.
    /// - Numbers are neither NaN nor infinity.
    /// The JSON object
    /// - Parameter jsonObject: The JSON object
    /// - Returns: A Smithy `Document` containing the JSON.
    static func make(from jsonObject: Any) throws -> Document {
        let doc: SmithyDocument
        if let object = jsonObject as? [String: Any] {
            doc = StringMapDocument(value: try object.mapValues { try Self.make(from: $0) })
        } else if let array = jsonObject as? [Any] {
            doc = ListDocument(value: try array.map { try Self.make(from: $0) })
        } else if let nsNumber = jsonObject as? NSNumber {
            // Check if the NSNumber is a boolean, else treat it as double
            if CFGetTypeID(nsNumber) == CFBooleanGetTypeID() {
                doc = BooleanDocument(value: nsNumber.boolValue)
            } else {
                doc = DoubleDocument(value: nsNumber.doubleValue)
            }
        } else if let string = jsonObject as? String {
            doc = StringDocument(value: string)
        } else if jsonObject is NSNull {
            doc = NullDocument()
        } else {
            throw DocumentError.invalidJSONData
        }
        return Document(doc)
    }
}
