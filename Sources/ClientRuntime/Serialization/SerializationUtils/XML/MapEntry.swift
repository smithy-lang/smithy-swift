//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct MapEntry<K, V, CustomKeyName, CustomValueName>: Decodable where K: Decodable, V: Decodable {
    public let entry: [MapKeyValue<K, V, CustomKeyName, CustomValueName>]?
    public enum CodingKeys: String, CodingKey {
        case entry
    }
}
