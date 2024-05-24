//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONSerialization
import class Foundation.NSNull
import class Foundation.NSNumber

extension Writer {

    public func data() throws -> Data {
        trimTree()
        return try JSONSerialization.data(withJSONObject: jsonObject(), options: [.fragmentsAllowed])
    }

    private func trimTree() {
        guard jsonNode != nil else {
            parent?.children.removeAll { $0 === self }
            parent = nil
            return
        }
        children.forEach { $0.trimTree() }
    }

    private func jsonObject() -> Any {
        switch jsonNode {
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
        case .array:
            return children.compactMap { $0.jsonObject() }
        case .object:
            return Dictionary(uniqueKeysWithValues: children.map { ($0.nodeInfo, $0.jsonObject()) })
        case nil:
            // This case will never happen since tree was trimmed of nils before this method is called
            return NSNull()
        }
    }
}
