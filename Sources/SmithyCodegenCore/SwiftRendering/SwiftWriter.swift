//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.Bundle
import struct Foundation.Data
import struct Foundation.URL

class SwiftWriter {

    private var lines: [String]

    var indentLevel = 0

    init(includeHeader: Bool = true) {
        if includeHeader {
            let defaultHeaderFileURL = Bundle.module.url(forResource: "DefaultSwiftHeader", withExtension: "txt")!
            // swiftlint:disable:next force_try
            let defaultHeader = try! String(data: Data(contentsOf: defaultHeaderFileURL), encoding: .utf8)!
            self.lines = defaultHeader.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        } else {
            self.lines = []
        }
    }

    func indent() {
        indentLevel += 4
    }

    func dedent() {
        indentLevel -= 4
    }

    func write(_ line: String) {
        if line.isEmpty {
            // Don't write whitespace to an empty line
            lines.append("")
        } else {
            // Write whitespace for the indent level, then the line content
            lines.append(String(repeating: " ", count: indentLevel) + line)
        }
    }

    /// Removes previously written text.
    ///
    /// If the unwritten text matches the end of the last written line, then that text will be removed from that line.
    ///
    /// If the unwritten text is `\n`, then the entire previous line will be removed only if it is an empty line.
    /// Otherwise, unwriting `\n` has no effect.
    /// - Parameter text: The text to be removed from the last written text.
    func unwrite(_ text: String) {
        guard let lastIndex = lines.indices.last else { return }
        if text == "\n" && lines[lastIndex] == "" {
            _ = lines.removeLast()
        } else if lines[lastIndex].hasSuffix(text) {
            lines[lastIndex].removeLast(text.count)
        }
    }

    func openBlock(_ openWith: String, _ closeWith: String, contents: (SwiftWriter) throws -> Void) rethrows {
        write(openWith)
        indent()
        try contents(self)
        dedent()
        write(closeWith)
    }

    var contents: String {
        return lines.joined(separator: "\n").appending("\n")
    }
}
