/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

/// Expands the compact Header Representation of List of any type except Dates
public func splitHeaderListValues(_ value: String?) -> [String]? {
    guard let value = value else { return nil}
    return value.components(separatedBy: ",").map { $0.trim() }
}

/// Expands the compact HTTP Header Representation of List of Dates
public func splitHttpDateHeaderListValues(_ value: String?) throws -> [String]? {
    guard let value = value else { return nil}
    
    let separator = ","
    let totalSeparators = value.components(separatedBy: separator).count - 1
    if totalSeparators <= 1 {
        return [value]
    } else if totalSeparators % 2 == 0 {
        return splitHeaderListValues(value)
    }
    
    var cnt = 0
    var splits: [String] = []
    var start = 0
    var startIdx = value.index(value.startIndex, offsetBy: start)

    for i in 1...value.count {
        let currIdx = value.index(value.startIndex, offsetBy: i-1)
        if value[currIdx] == "," {
            cnt += 1
        }

        // split on every other ','
        if cnt > 1 {
            startIdx = value.index(value.startIndex, offsetBy: start)
            splits.append(String(value[startIdx..<currIdx]).trim())
            start = i + 1
            cnt = 0
        }
    }

    if start < value.count {
        startIdx = value.index(value.startIndex, offsetBy: start)
        splits.append(String(value[startIdx..<value.endIndex]).trim())
    }

    return splits
}

public enum HeaderDeserializationError: Error {
    case invalidTimestampHeaderList(value: String)
    case invalidTimestampHeader(value: String)
    case invalidBooleanHeaderList(value: String)
    case invalidNumbersHeaderList(value: String)
    case invalidStringHeaderList(value: String)
}

extension HeaderDeserializationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidTimestampHeaderList(let value):
            return NSLocalizedString("Invalid HTTP Header List with Timestamps: \(value)",
                comment: "Client Deserialization Error")
        case .invalidTimestampHeader(let value):
            return NSLocalizedString("Invalid HTTP Header with Timestamp: \(value)",
            comment: "Client Deserialization Error")
        case .invalidBooleanHeaderList(let value):
            return NSLocalizedString("Invalid HTTP Header List with Booleans: \(value)",
                comment: "Client Deserialization Error")
        case .invalidNumbersHeaderList(let value):
            return NSLocalizedString("Invalid HTTP Header List with Booleans: \(value)",
                comment: "Client Deserialization Error")
        case .invalidStringHeaderList(let value):
            return NSLocalizedString("Invalid HTTP Header List with Strings: \(value)",
                comment: "Client Deserialization Error")
        }
    }
}

extension HeaderDeserializationError: Equatable {
    
}
