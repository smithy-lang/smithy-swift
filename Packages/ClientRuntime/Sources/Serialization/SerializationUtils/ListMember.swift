//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct CollectionMember<CustomMemberName> {
    public enum CodingKeys: String, CodingKey {
        case member

        public var rawValue: String {
            switch self {
            case .member: return customMemberName()
            }
        }

        func customMemberName() -> String {
            return String(describing: CustomMemberName.self)
        }
    }
}
