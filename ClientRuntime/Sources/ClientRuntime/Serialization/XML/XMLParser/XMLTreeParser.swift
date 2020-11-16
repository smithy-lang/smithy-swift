// TODO:: Add copyrights

import Foundation

class XMLTreeParser: NSObject {

    var root: XMLElementRepresentable?
    private var stack: [XMLElementRepresentable] = []
    private let trimValueWhitespaces: Bool

    init(trimValueWhitespaces: Bool = true) {
        self.trimValueWhitespaces = trimValueWhitespaces
        super.init()
    }

    static func parse(
        with data: Data,
        errorContextLength length: UInt,
        shouldProcessNamespaces: Bool,
        trimValueWhitespaces: Bool
    ) throws -> XMLContainer {
        let parser = XMLTreeParser(trimValueWhitespaces: trimValueWhitespaces)

        let node = try parser.parse(
            with: data,
            errorContextLength: length,
            shouldProcessNamespaces: shouldProcessNamespaces
        )

        return node.transformToKeyBasedContainer()
    }

    func parse(
            with data: Data,
            errorContextLength: UInt,
            shouldProcessNamespaces: Bool
        ) throws -> XMLElementRepresentable {

            let xmlTreeParser = XMLParser(data: data)
            xmlTreeParser.shouldProcessNamespaces = shouldProcessNamespaces
            xmlTreeParser.delegate = self

            guard !xmlTreeParser.parse() || root == nil else {
                return root! //TODO:: when is this case possible?
            }

            guard let error = xmlTreeParser.parserError else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: [],
                    debugDescription: "The given data could not be parsed into XML."
                ))
            }

            // `lineNumber` isn't 0-indexed, so 0 is an invalid value for context
            guard errorContextLength > 0 && xmlTreeParser.lineNumber > 0 else {
                throw error
            }

            let string = String(data: data, encoding: .utf8) ?? ""

            // get the location in xml where error occurred based on errorContextLength
            let lines = string.split(separator: "\n")
            var errorPosition = 0
            let offset = Int(errorContextLength / 2)
            for index in 0..<xmlTreeParser.lineNumber - 1 {
                errorPosition += lines[index].count
            }
            errorPosition += xmlTreeParser.columnNumber

            var lowerBoundIndex = 0
            if errorPosition - offset > 0 {
                lowerBoundIndex = errorPosition - offset
            }

            var upperBoundIndex = string.count
            if errorPosition + offset < string.count {
                upperBoundIndex = errorPosition + offset
            }

            #if compiler(>=5.0)
            let lowerBound = String.Index(utf16Offset: lowerBoundIndex, in: string)
            let upperBound = String.Index(utf16Offset: upperBoundIndex, in: string)
            #else
            let lowerBound = String.Index(encodedOffset: lowerBoundIndex)
            let upperBound = String.Index(encodedOffset: upperBoundIndex)
            #endif

            let context = string[lowerBound..<upperBound]

            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: """
                \(error.localizedDescription) \
                at line \(xmlTreeParser.lineNumber), column \(xmlTreeParser.columnNumber):
                `\(context)`
                """,
                underlyingError: error
            ))
        }

        func withCurrentElement(_ xmlElementRepresentable: (inout XMLElementRepresentable) throws -> Void) rethrows {
            guard !stack.isEmpty else {
                return
            }
            try xmlElementRepresentable(&stack[stack.count - 1])
        }

        func process(string: String) -> String {
            return trimValueWhitespaces
                ? string.trimmingCharacters(in: .whitespacesAndNewlines)
                : string
        }
    }

    extension XMLTreeParser: XMLParserDelegate {
        func parserDidStartDocument(_: XMLParser) {
            root = nil
            stack = []
        }

        func parser(_: XMLParser,
                    didStartElement elementName: String,
                    namespaceURI: String?,
                    qualifiedName: String?,
                    attributes attributeDict: [String: String] = [:]) {
            #if os(Linux) && !compiler(>=5.1)
            // For some reason, element names on linux are coming out with the namespace after the name
            // https://bugs.swift.org/browse/SR-11191
            let elementName = elementName.components(separatedBy: ":").reversed().joined(separator: ":")
            #endif
            let attributes = attributeDict.map { key, value in
                XMLAttributeRepresentable(key: key, value: value)
            }
            let element = XMLElementRepresentable(key: elementName, attributes: attributes)
            stack.append(element)
        }

        func parser(_: XMLParser,
                    didEndElement _: String,
                    namespaceURI _: String?,
                    qualifiedName _: String?) {
            guard let element = stack.popLast() else {
                return
            }

            withCurrentElement { currentElement in
                currentElement.append(element: element, forKey: element.key)
            }

            if stack.isEmpty {
                root = element
            }
        }

        func parser(_: XMLParser, foundCharacters string: String) {
            let processedString = process(string: string)
            guard !processedString.isEmpty, !string.isEmpty else {
                return
            }

            withCurrentElement { currentElement in
                currentElement.append(string: processedString)
            }
        }
    }
