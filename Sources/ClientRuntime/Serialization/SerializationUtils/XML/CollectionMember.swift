//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
 * Used for decoding lists for RestXML
 */
public struct CollectionMember<M, MemberCodingKey>: Codable where M: Codable {
    public let member: [M]
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
