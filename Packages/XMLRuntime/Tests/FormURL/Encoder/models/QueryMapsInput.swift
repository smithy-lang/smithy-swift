//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import ClientRuntime
@testable import XMLRuntime

public struct QueryMapsInput: Equatable {
    public let flattenedMap: [String: String]?
    public let mapArg: [String: String]?

    public init (
        flattenedMap: [String: String]? = nil,
        mapArg: [String: String]? = nil
    ) {
        self.flattenedMap = flattenedMap
        self.mapArg = mapArg
    }
}

extension QueryMapsInput: Encodable, Reflection {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        if let flattenedMap = flattenedMap {
            if flattenedMap.isEmpty {
                _ =  container.nestedContainer(keyedBy: Key.self, forKey: Key("FlattenedMap"))
            } else {
                for (index, element) in flattenedMap.enumerated() {
                    let stringKey0 = element.key
                    let stringValue0 = element.value
                    var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("FlattenedMap.\(index.advanced(by: 1))"))
                    try nestedContainer0.encode(stringKey0, forKey: Key("key"))
                    try nestedContainer0.encode(stringValue0, forKey: Key("value"))
                }
            }
        }
        if let mapArg = mapArg {
            var mapArgContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("MapArg"))
            for (index, element0) in mapArg.enumerated() {
                let stringKey0 = element0.key
                let stringValue0 = element0.value
                var entryContainer0 = mapArgContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry.\(index.advanced(by: 1))"))
                var keyContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                try keyContainer0.encode(stringKey0, forKey: Key(""))
                var valueContainer0 = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                try valueContainer0.encode(stringValue0, forKey: Key(""))
            }
        }
    }
}
