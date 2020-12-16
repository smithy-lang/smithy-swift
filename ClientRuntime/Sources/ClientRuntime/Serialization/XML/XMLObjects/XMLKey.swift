/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLKey.swift
//  XMLParser

import Foundation

struct XMLKey: CodingKey {
    public let stringValue: String
    public let intValue: Int?

    public init?(stringValue: String) {
        self.init(key: stringValue)
    }

    public init?(intValue: Int) {
        self.init(index: intValue)
    }

    public init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }

    init(key: String) {
        self.init(stringValue: key, intValue: nil)
    }

    init(index: Int) {
        self.init(stringValue: "\(index)", intValue: index)
    }

    static let `super` = XMLKey(stringValue: "super")!
}
