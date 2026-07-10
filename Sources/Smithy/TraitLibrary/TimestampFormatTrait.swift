//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
public final class TimestampFormatTrait: RuntimeTrait {

    public static var id: ShapeID { .init("smithy.api", "timestampFormat") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public let format: TimestampFormat

    public init(node: Node) throws {
        guard let formatString = node.string else {
            throw TraitError("TimestampFormatTrait does not have string value")
        }
        guard let format = Self.timestampFormat(from: formatString) else {
            throw TraitError("TimestampFormatTrait string value is not valid")
        }
        self.format = format
    }

    public var node: Node { .string(Self.string(from: format)) }

    private static func timestampFormat(from string: String) -> TimestampFormat? {
        switch string {
        case "date-time":
            return .dateTime
        case "http-date":
            return .httpDate
        case "epoch-seconds":
            return .epochSeconds
        default:
            return nil
        }
    }

    private static func string(from timestampFormat: TimestampFormat) -> String {
        switch timestampFormat {
        case .dateTime:
            return "date-time"
        case .httpDate:
            return "http-date"
        case .epochSeconds:
            return "epoch-seconds"
        }
    }
}
