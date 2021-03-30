//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
public struct MapEntry<K, V, CK, CV>: Codable where K: Codable, V: Codable {
    let entry: [MapKeyValue<K, V, CK, CV>]?
    public enum CodingKeys: String, CodingKey {
        case entry
    }
}
