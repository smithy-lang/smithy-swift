//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.Bundle
import struct Foundation.Data
import struct Foundation.URL

/// A type used to write structured source code text.
///
/// Based heavily on the Kotlin-based code generator's `SwiftWriter` type.
class SwiftWriter {

    private var lines: [String]

    var indentLevel = 0

    // One indent/dedent will move indentation by this number of spaces.
    let indentStep = 4

    /// Creates a new ``SwiftWriter``.
    /// - Parameter includeHeader: Whether to include the standard header at the top of the generated source content.
    ///   The header contents are in a resource named `DefaultSwiftHeader.txt`.
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
    
    /// Indents the writer by one additional step
    func indent() {
        indentLevel += indentStep
    }

    /// Dedents the writer by one step
    func dedent() {
        indentLevel -= indentStep
    }

    /// Writes a line of text to the source
    /// - Parameter line: The text to be written.
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
    
    /// Writes a "block" of text with opening text, closing text, and an indented body between.
    /// - Parameters:
    ///   - openWith: The text to open the block
    ///   - closeWith: The text to close the block
    ///   - contents: A closure that accepts a SwiftWriter as a param, and writes the indented body of the block.
    func openBlock(_ openWith: String, _ closeWith: String, contents: (SwiftWriter) throws -> Void) rethrows {
        write(openWith)
        indent()
        try contents(self)
        dedent()
        write(closeWith)
    }
    
    /// Returns the entire source contents of the writer, from the header (if any) to the last line written,
    /// with individual lines joined by newlines, suitable for writing to a Swift source file.
    var contents: String {
        return lines.joined(separator: "\n").appending("\n")
    }
}
