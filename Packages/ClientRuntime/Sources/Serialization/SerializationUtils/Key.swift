/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public struct Key: CodingKey {
    public let stringValue: String
    public init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public let intValue: Int?
    public init?(intValue: Int) {
        return nil
    }
}
