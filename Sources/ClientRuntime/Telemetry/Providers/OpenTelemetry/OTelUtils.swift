//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if !(os(Linux) || os(visionOS))
import OpenTelemetryApi

import Smithy

extension Attributes {
    public func toOtelAttributes() -> [String: AttributeValue] {
        let keys: [String] = self.getKeys()
        var otelKeys: [String: AttributeValue] = [:]

        guard !keys.isEmpty else {
            return [:]
        }

        keys.forEach { key in
            guard let value = self.get(key: AttributeKey(name: key)) else { return }

            // Handle different types that AttributeValue can accept
            switch value {
            case let stringValue as String:
                otelKeys[key] = AttributeValue.string(stringValue)
            case let intValue as Int:
                otelKeys[key] = AttributeValue.int(intValue)
            case let doubleValue as Double:
                otelKeys[key] = AttributeValue.double(doubleValue)
            case let boolValue as Bool:
                otelKeys[key] = AttributeValue.bool(boolValue)
            case let arrayValue as [String]:
                otelKeys[key] = AttributeValue.stringArray(arrayValue)
            case let arrayValue as [Int]:
                otelKeys[key] = AttributeValue.intArray(arrayValue)
            case let arrayValue as [Double]:
                otelKeys[key] = AttributeValue.doubleArray(arrayValue)
            case let arrayValue as [Bool]:
                otelKeys[key] = AttributeValue.boolArray(arrayValue)
            default:
                // For any other type, convert to string
                otelKeys[key] = AttributeValue.string(String(describing: value))
            }
        }

        return otelKeys
    }
}
#endif
