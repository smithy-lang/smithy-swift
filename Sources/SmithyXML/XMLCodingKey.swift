//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct XMLCodingKey: CodingKey {

    public enum Location {
        case element
        case attribute
    }

    public let intValue: Int?
    public let stringValue: String
    public let location: Location

    public init(stringValue: String) {
        self.init(stringValue, location: .element)
    }

    public init(intValue: Int) {
        self.init(intValue: intValue, location: .element)
    }

    public init(_ stringValue: String, location: Location = .element) {
        self.stringValue = stringValue
        self.intValue = Int(stringValue)
        self.location = location
    }

    public init(intValue: Int, location: Location) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
        self.location = location
    }

    var kind: XMLNode.Kind {
        switch location {
        case .element: return .element
        case .attribute: return .attribute
        }
    }
}
