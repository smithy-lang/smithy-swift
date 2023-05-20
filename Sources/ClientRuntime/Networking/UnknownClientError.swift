//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct UnknownClientError: Error {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }
}
