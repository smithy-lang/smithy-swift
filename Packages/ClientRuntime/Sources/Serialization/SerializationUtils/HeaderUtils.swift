/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

fileprivate extension StringProtocol {
    subscript(_ offset: Int) -> Element {
        self[index(startIndex, offsetBy: offset)]
    }
    
    subscript(_ range: Range<Int>) -> SubSequence {
        prefix(range.lowerBound+range.count).suffix(range.count)
    }
    
    subscript(_ range: ClosedRange<Int>) -> SubSequence {
        prefix(range.lowerBound+range.count).suffix(range.count)
    }
    
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence {
        prefix(range.upperBound.advanced(by: 1))
    }
    
    subscript(_ range: PartialRangeUpTo<Int>) -> SubSequence {
        prefix(range.upperBound)
    }
    
    subscript(_ range: PartialRangeFrom<Int>) -> SubSequence {
        suffix(Swift.max(0, count-range.lowerBound))
    }
}


fileprivate extension String {
    func readNextQuoted(startIdx: Int, delim: Character = ",") throws -> (Int, String) {
        // startIdx is start of the quoted value, there must be at least an ending quotation mark
        if !(startIdx + 1 < count) {
            throw HeaderDeserializationError.invalidStringHeaderList(value: self)
        }
        
        // find first non-escaped quote or end of string
        var endIdx = startIdx + 1
        while endIdx < count {
            let char = self[endIdx]
            if char == "\\" {
                // skip escaped chars
                endIdx += 1
            } else if char == "\"" {
                break
            }
            endIdx += 1
        }
        
        let next = self[startIdx + 1..<endIdx]
        
        // consume trailing quote
        if endIdx >= count || self[endIdx] != "\"" {
            throw HeaderDeserializationError.invalidStringHeaderList(value: self)
        }
        assert(endIdx < count)
        assert(self[endIdx] == "\"")
        
        endIdx += 1
        
        // consume delim
        while endIdx < count {
            let char = self[endIdx]
            if char == " " || char == "\t" {
                endIdx += 1
            } else if char == delim {
                endIdx += 1
                break
            } else {
                throw HeaderDeserializationError.invalidStringHeaderList(value: self)
            }
        }
        
        let unescaped = next.replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
        
        return (endIdx, unescaped)
    }
    
    func readNextUnquoted(startIdx: Int, delim: Character = ",") -> (Int, String) {
        assert(startIdx < self.count)
        
        var endIdx = startIdx
        
        while endIdx < count && self[endIdx] != delim {
            endIdx += 1
        }
        
        let next = self[startIdx..<endIdx]
        if endIdx < count && self[endIdx] == delim {
            endIdx += 1
        }
        
        return (endIdx, next.trim())
    }
}

// chars in an HTTP header value that require quotations
fileprivate let QUOTABLE_HEADER_VALUE_CHARS = "\",()"

public func quoteHeaderValue(_ value: String) -> String  {
    if value.trim().count != value.count || value.contains(where: { char1 in
        QUOTABLE_HEADER_VALUE_CHARS.contains { char2 in
            char1 == char2
        }
    }) {
        let formatted = value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(formatted)\""
    } else {
        return value
    }
}

/// Expands the compact Header Representation of List of any type except Dates
public func splitHeaderListValues(_ value: String?) throws -> [String]? {
    guard let value = value else {
        return nil
    }
    var results: [String] = []
    var currIdx = 0
    
    while currIdx < value.count {
        let next: (idx: Int, str: String)
        
        switch value[currIdx] {
        case " ":
            currIdx += 1
            continue
        case "\t":
            currIdx += 1
            continue
        case "\"":
            next = try value.readNextQuoted(startIdx: currIdx)
        default:
            next = value.readNextUnquoted(startIdx: currIdx)
        }
        
        currIdx = next.idx
        results.append(next.str)
    }
    
    return results
    
}

/// Expands the compact HTTP Header Representation of List of Dates
public func splitHttpDateHeaderListValues(_ value: String?) throws -> [String]? {
    guard let value = value else { return nil}
    
    let n = value.filter ({$0 == ","}).count
    
    if n <= 1 {
        return [value]
    } else if n % 2 == 0 {
        throw HeaderDeserializationError.invalidTimestampHeaderList(value: value)
    }
    
    var cnt = 0
    var splits: [String] = []
    var startIdx = 0
    
    for i in 0..<value.count {
        if value[i] == "," {
            cnt += 1
        }
        
        // split on every other ','
        if cnt > 1 {
            splits.append(value[startIdx..<i].trim())
            startIdx = i + 1
            cnt = 0
        }
    }
    
    if startIdx < value.count {
        splits.append(value[startIdx...].trim())
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
