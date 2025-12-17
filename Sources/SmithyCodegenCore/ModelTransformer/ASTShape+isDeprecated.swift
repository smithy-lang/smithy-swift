//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeZone
import enum Smithy.Node

// protocol HasASTTraits {
//    var traits: [String: ASTNode]? { get }
// }
//
// extension ASTShape: HasASTTraits {}
//
// extension ASTMember: HasASTTraits {}
//
// extension HasASTTraits {
//
//    var isDeprecated: Bool {
//        guard let node = traits?["smithy.api#deprecated"] else { return false }
//        guard case .object(let object) = node else { fatalError("Deprecated trait content is not an object") }
//        guard case .string(let since) = object["since"] else { return false }
//        guard let deprecationDate = formatter.date(from: since) else { return false }
//
//        let removeIfDeprecatedBefore = Date(timeIntervalSince1970: 1726531200.0) // this is '2024-09-17'
//        return deprecationDate < removeIfDeprecatedBefore
//    }
// }
//
// private let formatter = {
//    let df = DateFormatter()
//    df.dateFormat = "yyyy-MM-dd"
//    df.timeZone = TimeZone(identifier: "UTC")
//    df.locale = Locale(identifier: "en_US_POSIX")
//    return df
// }()
