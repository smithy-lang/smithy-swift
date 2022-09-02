/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

fileprivate extension String {
    func readNextQuoted(startIdx: String.Index, delim: Character = ",") throws -> (String.Index, String) {
        // startIdx is start of the quoted value, there must be at least an ending quotation mark
        if !(self.index(after: startIdx) < self.endIndex) {
            throw HeaderDeserializationError.invalidStringHeaderList(value: self)
        }
        
        // find first non-escaped quote or end of string
        var endIdx = self.index(after: startIdx)
        while endIdx < self.endIndex {
            let char = self[endIdx]
            if char == "\\" {
                // skip escaped chars
                endIdx = self.index(after: endIdx)
            } else if char == "\"" {
                break
            }
            endIdx = self.index(after: endIdx)
        }
        
        let next = self[self.index(after: startIdx)..<endIdx]
        
        // consume trailing quote
        if endIdx >= self.endIndex || self[endIdx] != "\"" {
            throw HeaderDeserializationError.invalidStringHeaderList(value: self)
        }
        assert(endIdx < self.endIndex)
        assert(self[endIdx] == "\"")
        
        endIdx = self.index(after: endIdx)
        
        // consume delim
        while endIdx < self.endIndex {
            let char = self[endIdx]
            if char == " " || char == "\t" {
                endIdx = self.index(after: endIdx)
            } else if char == delim {
                endIdx = self.index(after: endIdx)
                break
            } else {
                throw HeaderDeserializationError.invalidStringHeaderList(value: self)
            }
        }
        
        let unescaped = next.replacingOccurrences(of: "\\\"", with: "\"")
            .replacingOccurrences(of: "\\\\", with: "\\")
        
        return (endIdx, unescaped)
    }
    
    func readNextUnquoted(startIdx: String.Index, delim: Character = ",") -> (String.Index, String) {
        assert(startIdx < self.endIndex)
        
        var endIdx = startIdx
        
        while endIdx < self.endIndex && self[endIdx] != delim {
            endIdx = self.index(after: endIdx)
        }
        
        let next = self[startIdx..<endIdx]
        if endIdx < self.endIndex && self[endIdx] == delim {
            endIdx = self.index(after: endIdx)
        }
        
        return (endIdx, next.trim())
    }
}

// chars in an HTTP header value that require quotations
private let QUOTABLE_HEADER_VALUE_CHARS = "\",()"

public func quoteHeaderValue(_ value: String) -> String {
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
    var currIdx = value.startIndex
    
    while currIdx < value.endIndex {
        let next: (idx: String.Index, str: String)
        
        switch value[currIdx] {
        case " ", "\t":
            currIdx = value.index(after: currIdx)
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
    
    let n = value.filter({$0 == ","}).count
    
    if n <= 1 {
        return [value]
    } else if n % 2 == 0 {
        throw HeaderDeserializationError.invalidTimestampHeaderList(value: value)
    }
    
    var cnt = 0
    var splits: [String] = []
    var startIdx = value.startIndex
    
    for i in value.indices[value.startIndex..<value.endIndex] {
        if value[i] == "," {
            cnt += 1
        }
        
        // split on every other ','
        if cnt > 1 {
            splits.append(value[startIdx..<i].trim())
            startIdx = value.index(after: i)
            cnt = 0
        }
    }
    
    if startIdx < value.endIndex {
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
