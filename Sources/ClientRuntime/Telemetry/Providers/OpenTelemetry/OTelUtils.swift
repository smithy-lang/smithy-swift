//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

 #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// OpenTelemetryApi specific imports
@preconcurrency import enum OpenTelemetryApi.AttributeValue
@preconcurrency import class OpenTelemetryApi.AttributeArray

// Smithy imports
import struct Smithy.Attributes
import struct Smithy.AttributeKey

extension Attributes {
    public func toOtelAttributes() -> [String: AttributeValue] {
        let keys: [String] = self.getKeys()
        var otelKeys: [String: AttributeValue] = [:]

        guard !keys.isEmpty else {
            return [:]
        }

        keys.forEach { key in
            // Try to get the value as different types
            if let stringValue = self.get(key: AttributeKey<String>(name: key)) {
                otelKeys[key] = AttributeValue.string(stringValue)
            } else if let intValue = self.get(key: AttributeKey<Int>(name: key)) {
                otelKeys[key] = AttributeValue.int(intValue)
            } else if let doubleValue = self.get(key: AttributeKey<Double>(name: key)) {
                otelKeys[key] = AttributeValue.double(doubleValue)
            } else if let boolValue = self.get(key: AttributeKey<Bool>(name: key)) {
                otelKeys[key] = AttributeValue.bool(boolValue)
            } else if let arrayValue = self.get(key: AttributeKey<[String]>(name: key)) {
                let attributeArray = arrayValue.map { AttributeValue.string($0) }
                otelKeys[key] = AttributeValue.array(AttributeArray(values: attributeArray))
            } else if let arrayValue = self.get(key: AttributeKey<[Int]>(name: key)) {
                let attributeArray = arrayValue.map { AttributeValue.int($0) }
                otelKeys[key] = AttributeValue.array(AttributeArray(values: attributeArray))
            } else if let arrayValue = self.get(key: AttributeKey<[Double]>(name: key)) {
                let attributeArray = arrayValue.map { AttributeValue.double($0) }
                otelKeys[key] = AttributeValue.array(AttributeArray(values: attributeArray))
            } else if let arrayValue = self.get(key: AttributeKey<[Bool]>(name: key)) {
                let attributeArray = arrayValue.map { AttributeValue.bool($0) }
                otelKeys[key] = AttributeValue.array(AttributeArray(values: attributeArray))
            }
            // If none of the above types match, the value is skipped
        }

        return otelKeys
    }
}
#endif
