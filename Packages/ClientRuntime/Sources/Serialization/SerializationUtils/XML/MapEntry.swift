//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
public struct MapEntry<K, V>: Codable where K: Codable, V: Codable {
    let entry: [MapKeyValue<K, V>]?
    public enum CodingKeys: String, CodingKey {
        case entry
    }
}
