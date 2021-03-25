//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
public struct MapKeyValue<K, V>: Codable where K: Codable, V: Codable {
    public let key: K
    public let value: V
    public enum CodingKeys: String, CodingKey {
        case key
        case value
    }
}
