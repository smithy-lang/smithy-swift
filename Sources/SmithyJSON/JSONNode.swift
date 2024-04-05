//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSNull

enum JSONNode {
    case bool(Bool)
    case number(Double)
    case string(String)
    case null
    case array([JSONNode])
    case object([String: JSONNode])
}

extension JSONNode {

    init(jsonObject: Any) throws {
        if let array = jsonObject as? [Any] {
            self = .array(try array.map { try JSONNode(jsonObject: $0) })
        } else if let bool = jsonObject as? Bool {
            self = .bool(bool)
        } else if let number = jsonObject as? Double {
            self = .number(number)
        } else if let string = jsonObject as? String {
            self = .string(string)
        } else if jsonObject is NSNull {
            self = .null
        } else if let object = jsonObject as? [String: Any] {
            self = .object(try object.mapValues { try JSONNode(jsonObject: $0) })
        } else {
            throw JSONError.unknownJSONContent
        }
    }

    var jsonObject: Any {
        switch self {
        case .bool(let bool):
            return bool
        case .number(let number):
            return number
        case .string(let string):
            return string
        case .null:
            return NSNull()
        case .array(let array):
            return array.map { $0.jsonObject }
        case .object(let object):
            return object.mapValues { $0.jsonObject }
        }
    }
}

enum JSONError: Error {
    case unknownJSONContent
}
