//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyStreamsAPI.ByteStream

extension ByteStream: Equatable {
    public static func ==(lhs: ByteStream, rhs: ByteStream) -> Bool {
        switch (lhs, rhs) {
        case (.data(let lhsData), .data(let rhsData)):
            return lhsData == rhsData
        case (.stream(let lhsStream), .stream(let rhsStream)):
            // swiftlint:disable force_try
            return try! lhsStream.readToEnd() == rhsStream.readToEnd()
            // swiftlint:enable force_try
        case (.noStream, .noStream):
            return true
        default:
            return false
        }
    }
}
