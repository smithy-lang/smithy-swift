//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct MapKeyValue<K, V, CustomKeyName, CustomValueName>: Decodable where K: Decodable, V: Decodable {
    public let key: K
    public let value: V

    public enum CodingKeys: String, CodingKey {
        case key
        case value

        public var rawValue: String {
            switch self {
            case .key: return customKeyName()
            case .value: return customValueName()
            }
        }
        func customKeyName() -> String {
            return String(describing: CustomKeyName.self)
        }
        func customValueName() -> String {
            return String(describing: CustomValueName.self)
        }
    }
}
