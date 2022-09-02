//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
 * Used to for wrapped lists that use a custom coding key for `member` for RestXML
 */
public struct CollectionMemberCodingKey<MemberCodingKey> {
    public enum CodingKeys: String, CodingKey {
        case member

        public var rawValue: String {
            switch self {
            case .member: return customMemberName()
            }
        }

        func customMemberName() -> String {
            return String(describing: MemberCodingKey.self)
        }
    }
}
