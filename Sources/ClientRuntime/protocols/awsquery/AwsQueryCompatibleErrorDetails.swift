//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Error details presented for backwards-compatibility by services that have migrated from awsQuery.
public class AwsQueryCompatibleErrorDetails {
    public let code: String
    public let type: String

    public init(
        code: String,
        type: String
    ) {
        self.code = code
        self.type = type
    }

    /// Parses the `x-amzn-query-error` header value in format `code;type`.
    ///
    /// - Parameter value: The raw header value (e.g., "InvalidParameterValue;Sender")
    /// - Returns: Parsed error details if valid, `nil` if value is `nil`
    /// - Throws: `AwsQueryCompatibleParseError` if the value is malformed, has empty code, or empty type
    public static func parse(_ value: String?) throws -> AwsQueryCompatibleErrorDetails? {
        guard let value else {
            return nil
        }
        return try parseImpl(value)
    }
}

public enum AwsQueryCompatibleParseError: Error, CustomDebugStringConvertible {
    case malformedErrorString
    case emptyCode
    case emptyType

    public var debugDescription: String {
        switch self {
        case .malformedErrorString:
            return "value is malformed"
        case .emptyCode:
            return "code is empty"
        case .emptyType:
            return "type is empty"
        }
    }
}

// parse an awsQuery error from its string representation
// the value is formatted as `code;type` e.g. `AWS.SimpleQueueService.NonExistentQueue;Sender`.
private func parseImpl(_ error: String) throws -> AwsQueryCompatibleErrorDetails {
    let segments = error.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)

    guard segments.count == 2 else {
        throw AwsQueryCompatibleParseError.malformedErrorString
    }

    let code = String(segments[0])
    let type = String(segments[1])

    guard !code.isEmpty else {
        throw AwsQueryCompatibleParseError.emptyCode
    }
    guard !type.isEmpty else {
        throw AwsQueryCompatibleParseError.emptyType
    }

    return AwsQueryCompatibleErrorDetails(code: code, type: type)
}
