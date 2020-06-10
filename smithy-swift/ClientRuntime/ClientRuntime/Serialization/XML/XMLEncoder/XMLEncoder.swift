//
//  XMLEncoder.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//


import Foundation

public protocol DynamicNodeEncoding: Encodable {
    static func nodeEncoding(for key: CodingKey) -> NodeEncoding
}

extension Array: DynamicNodeEncoding where Element: DynamicNodeEncoding {
    public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
        return Element.nodeEncoding(for: key)
    }
}

extension DynamicNodeEncoding where Self: Collection, Self.Iterator.Element: DynamicNodeEncoding {
    public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
        return Element.nodeEncoding(for: key)
    }
}

open class XMLEncoder {
        /// The options set on the top-level encoder.
    var options: XMLEncoderOptions

    // MARK: - Constructing a XML Encoder

    /// Initializes `self` with default strategies.
    public init() {
        self.options =  XMLEncoderOptions()
    }
    
    /// Intializes an ecoder with given options
    public init(options: XMLEncoderOptions) {
        self.options = options
    }

    // MARK: - Encoding Values

    /// Encodes the given top-level value and returns its XML representation.
    ///
    /// - parameter value: The value to encode.
    /// - parameter withRootKey: the key used to wrap the encoded values. The
    ///   default value is inferred from the name of the root type.
    /// - parameter rootAttributes: the list of attributes to be added to the root node
    /// - returns: A new `Data` value containing the encoded XML data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming
    /// floating-point value is encountered during encoding, and the encoding
    /// strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = XMLEncoderImplementation(options: options, nodeEncodings: [])
        encoder.nodeEncodings.append(options.nodeEncodingStrategy.nodeEncodings(forType: T.self, with: encoder))

        let topLevel = try encoder.addToXMLContainer(value)
        let attributes = options.rootAttributes?.map(XMLAttributeRepresentable.init) ?? []

        let elementOrNone: XMLElementRepresentable?

        let rootKey = options.rootKey ?? "\(T.self)".convert(for: options.keyEncodingStrategy)

        let isStringBoxCDATA = options.stringEncodingStrategy == .cdata

        if let keyedBox = topLevel as? XMLKeyBasedContainer {
            elementOrNone = XMLElementRepresentable(
                key: rootKey,
                isStringBoxCDATA: isStringBoxCDATA,
                box: keyedBox,
                attributes: attributes
            )
        } else if let unkeyedBox = topLevel as? XMLArrayBasedContainer {
            elementOrNone = XMLElementRepresentable(
                key: rootKey,
                isStringBoxCDATA: isStringBoxCDATA,
                box: unkeyedBox,
                attributes: attributes
            )
        } else {
            fatalError("Unrecognized top-level element of type: \(type(of: topLevel))")
        }

        guard let element = elementOrNone else {
            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: [],
                debugDescription: "Unable to encode the given top-level value to XML."
            ))
        }

        return element.toXMLString(with: options.header, formatting: options.outputFormatting)
            .data(using: .utf8, allowLossyConversion: true)!
    }
}

private extension String {
    func convert(for encodingStrategy: KeyEncodingStrategy) -> String {
        switch encodingStrategy {
        case .useDefaultKeys:
            return self
        case .convertToSnakeCase:
            return KeyEncodingStrategy._convertToSnakeCase(self)
        case .convertToKebabCase:
            return KeyEncodingStrategy._convertToKebabCase(self)
        case .custom:
            return self
        case .capitalized:
            return KeyEncodingStrategy._convertToCapitalized(self)
        case .uppercased:
            return KeyEncodingStrategy._convertToUppercased(self)
        case .lowercased:
            return KeyEncodingStrategy._convertToLowercased(self)
        }
    }
}
