//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSNull
import class Foundation.NSNumber

indirect enum JSONValue: Equatable {
    case object([String: JSONValue])
    case list([JSONValue])
    case bool(Bool)
    case number(NSNumber)
    case string(String)
    case null

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
            return Dictionary(uniqueKeysWithValues: object.map { ($0, $1.jsonObject()) })
        }
    }
}
