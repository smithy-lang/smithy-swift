//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct TimestampFormatTrait: Trait {

    public enum Format: String {
        case dateTime = "date-time"
        case httpDate = "http-date"
        case epochSeconds = "epoch-seconds"
    }

    public static var id: ShapeID { .init("smithy.api", "timestampFormat") }

    public let format: Format

    public init(node: Node) throws {
        guard let formatString = node.string else {
            throw TraitError("TimestampFormatTrait does not have string value")
        }
        guard let format = Format(rawValue: formatString) else {
            throw TraitError("TimestampFormatTrait string value is not valid")
        }
        self.format = format
    }

    public var node: Node { .string(format.rawValue) }
}
