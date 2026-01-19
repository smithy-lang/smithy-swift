//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension String {

    /// Escapes special characters in the string, then surrounds it in double quotes
    /// to form a Swift string literal.
    var literal: String {
        let escaped = description
            .replacingOccurrences(of: "\0", with: "\\0")
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\'", with: "\\'")
        return "\"\(escaped)\""
    }

    var inBackticks: String {
        "`\(self)`"
    }

    var capitalized: String {
        let firstChar = self.first?.uppercased() ?? ""
        return "\(firstChar)\(self.dropFirst())"
    }
}
