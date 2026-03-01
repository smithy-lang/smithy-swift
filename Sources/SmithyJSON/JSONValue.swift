//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import func CoreFoundation.CFBooleanGetTypeID
import func CoreFoundation.CFGetTypeID
import class Foundation.NSNull
import class Foundation.NSNumber
import struct SmithySerialization.SerializerError

indirect enum JSONValue: Equatable {
    case object([String: JSONValue])
    case list([JSONValue])
    case bool(Bool)
    case number(NSNumber)
    case string(String)
    case null

    /// Creates a `JSONValue` from a Swift JSON object.
    ///
    /// The JSON object should obey the following:
    /// - The top level object is an NSArray or NSDictionary.
    /// - All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
    /// - All dictionary keys are instances of NSString.
    /// - Numbers are neither NaN nor infinity.
    /// - Parameter jsonObject: The JSON object to create the `JSONValue` from.
    init(from jsonObject: Any) throws {
        if let object = jsonObject as? [String: Any] {
            self = .object(try object.mapValues { try Self(from: $0) })
        } else if let array = jsonObject as? [Any] {
            self = .list(try array.map { try Self(from: $0) })
        } else if let nsNumber = jsonObject as? NSNumber {
            // Check if the NSNumber is a boolean, else treat it as double
            if CFGetTypeID(nsNumber) == CFBooleanGetTypeID() {
                self = .bool(nsNumber.boolValue)
            } else {
                self = .number(nsNumber)
            }
        } else if let string = jsonObject as? String {
            self = .string(string)
        } else if jsonObject is NSNull {
            self = .null
        } else {
            throw SerializerError("unsupported JSON object")
        }
    }
    
    /// Creates a JSON object suitable for serialization to JSON by `NSJSONSerialization.data()`.
    /// - Returns: The JSON object equivalent of the receiver.
    func jsonObject() -> Any {
        switch self {
        case .bool(let bool):
            return bool
        case .number(let number):
            guard !number.doubleValue.isNaN else { return "NaN" }
            switch number.doubleValue {
            case .infinity:
                return "Infinity"
            case -.infinity:
                return "-Infinity"
            default:
                return number
            }
        case .string(let string):
            return string
        case .null:
            return NSNull()
        case .list(let list):
            return list.map { $0.jsonObject() }
        case .object(let object):
            return object.mapValues { $0.jsonObject() }
        }
    }
}
