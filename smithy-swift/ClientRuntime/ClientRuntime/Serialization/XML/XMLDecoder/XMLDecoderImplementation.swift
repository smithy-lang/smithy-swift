//
//  XMLDecoderImplementation.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

class XMLDecoderImplementation: Decoder {
    // MARK: Properties

    /// The decoder's storage.
    var storage: XMLDecodingStorage = XMLDecodingStorage()

    /// Options set on the top-level decoder.
    let options: XMLDecoderOptions

    /// The path to the current point in encoding.
    public internal(set) var codingPath: [CodingKey]

    public var nodeDecodings: [(CodingKey) -> XMLDecoder.NodeDecoding]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any] {
        return options.userInfo
    }

    // The error context length
    open var errorContextLength: UInt = 0

    // MARK: - Initialization

    /// Initializes `self` with the given top-level container and options.
    init(
        referencing container: XMLContainer,
        options: XMLDecoderOptions,
        nodeDecodings: [(CodingKey) -> XMLDecoder.NodeDecoding],
        codingPath: [CodingKey] = []
    ) {
        storage.push(container: container)
        self.codingPath = codingPath
        self.nodeDecodings = nodeDecodings
        self.options = options
    }

    // MARK: - Decoder Methods

    internal func topContainer() throws -> XMLContainer {
        guard let topContainer = storage.topContainer() else {
            throw DecodingError.valueNotFound(XMLContainer.self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Cannot get decoding container -- empty container stack."
            ))
        }
        return topContainer
    }

    private func popContainer() throws -> XMLContainer {
        guard let topContainer = storage.popContainer() else {
            throw DecodingError.valueNotFound(XMLContainer.self, DecodingError.Context(
                codingPath: codingPath,
                debugDescription:
                """
                Cannot get decoding container -- empty container stack.
                """
            ))
        }
        return topContainer
    }

    public func container<Key>(keyedBy keyType: Key.Type) throws -> KeyedDecodingContainer<Key> {
        if let keyed = try topContainer() as? XMLSharedContainer<XMLKeyBasedContainer> {
            return KeyedDecodingContainer(XMLKeyedDecodingContainer<Key>(
                referencing: self,
                wrapping: keyed
            ))
        }
        
        return try keyedContainer(keyedBy: keyType)
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let topContainer = try self.topContainer()

        guard !topContainer.isNull else {
            throw DecodingError.valueNotFound(
                UnkeyedDecodingContainer.self,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription:
                    """
                    Cannot get unkeyed decoding container -- found null box instead.
                    """
                )
            )
        }

        switch topContainer {
        case let unkeyed as XMLSharedContainer<XMLArrayBasedContainer>:
            return XMLUnkeyedDecodingContainer(referencing: self, wrapping: unkeyed)
        case let keyed as XMLSharedContainer<XMLKeyBasedContainer>:
            return XMLUnkeyedDecodingContainer(
                referencing: self,
                wrapping: XMLSharedContainer(keyed.withShared { $0.elements.map(XMLSimpleKeyBasedContainer.init) })
            )
        default:
            throw DecodingError.typeMismatch(
                at: codingPath,
                expectation: [Any].self,
                reality: topContainer
            )
        }
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }

    private func keyedContainer<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let topContainer = try self.topContainer()
        let keyedBox: XMLKeyBasedContainer
        switch topContainer {
        case _ where topContainer.isNull:
            throw DecodingError.valueNotFound(
                KeyedDecodingContainer<Key>.self,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription:
                    """
                    Cannot get keyed decoding container -- found null box instead.
                    """
                )
            )
        case let string as XMLStringContainer:
            keyedBox = XMLKeyBasedContainer(
                elements: XMLKeyBasedStorage([("", string)]),
                attributes: XMLKeyBasedStorage()
            )
        case let containsEmpty as XMLSimpleKeyBasedContainer where containsEmpty.element is XMLNullContainer:
            keyedBox = XMLKeyBasedContainer(
                elements: XMLKeyBasedStorage([("", XMLStringContainer(""))]),
                attributes: XMLKeyBasedStorage()
            )
        case let unkeyed as XMLSharedContainer<XMLArrayBasedContainer>:
            guard let keyed = unkeyed.withShared({ $0.first }) as? XMLKeyBasedContainer else {
                fallthrough
            }
            keyedBox = keyed
        default:
            throw DecodingError.typeMismatch(
                at: codingPath,
                expectation: [String: Any].self,
                reality: topContainer
            )
        }
        let container = XMLKeyedDecodingContainer<Key>(
            referencing: self,
            wrapping: XMLSharedContainer(keyedBox)
        )
        return KeyedDecodingContainer(container)
    }
}

// MARK: - Concrete Value Representations

extension XMLDecoderImplementation {
    /// Returns the given box unboxed from a container.
    private func typedBox<T, B: XMLContainer>(_ box: XMLContainer, for valueType: T.Type) throws -> B {
        let error = DecodingError.valueNotFound(valueType, DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Expected \(valueType) but found null instead."
        ))
        switch box {
        case let typedBox as B:
            return typedBox
        case let unkeyedBox as XMLSharedContainer<XMLArrayBasedContainer>:
            guard let value = unkeyedBox.withShared({
                $0.first as? B
            }) else { throw error }
            return value
        case let keyedBox as XMLSharedContainer<XMLKeyBasedContainer>:
            guard
                let value = keyedBox.withShared({ $0.value as? B })
            else { throw error }
            return value
        case let singleKeyedBox as XMLSimpleKeyBasedContainer:
            if let value = singleKeyedBox.element as? B {
                return value
            } else if let box = singleKeyedBox.element as? XMLKeyBasedContainer, let value = box.elements[""].first as? B {
                return value
            } else {
                throw error
            }
        case is XMLNullContainer:
            throw error
        case let keyedBox as XMLKeyBasedContainer:
            guard
                let value = keyedBox.value as? B
            else { fallthrough }
            return value
        default:
            throw DecodingError.typeMismatch(
                at: codingPath,
                expectation: valueType,
                reality: box
            )
        }
    }

    func unbox(_ box: XMLContainer) throws -> Bool {
        let stringBox: XMLStringContainer = try typedBox(box, for: Bool.self)
        let string = stringBox.unboxed

        guard let boolBox = XMLBoolContainer(xmlString: string) else {
            throw DecodingError.typeMismatch(at: codingPath, expectation: Bool.self, reality: box)
        }

        return boolBox.unboxed
    }

    func unbox(_ box: XMLContainer) throws -> Decimal {
        let stringBox: XMLStringContainer = try typedBox(box, for: Decimal.self)
        let string = stringBox.unboxed

        guard let decimalBox = XMLDecimalContainer(xmlString: string) else {
            throw DecodingError.typeMismatch(at: codingPath, expectation: Decimal.self, reality: box)
        }

        return decimalBox.unboxed
    }

    func unbox<T: BinaryInteger & SignedInteger & Decodable>(_ box: XMLContainer) throws -> T {
        let stringBox: XMLStringContainer = try typedBox(box, for: T.self)
        let string = stringBox.unboxed

        guard let intBox = XMLIntContainer(xmlString: string) else {
            throw DecodingError.typeMismatch(at: codingPath, expectation: T.self, reality: box)
        }

        guard let int: T = intBox.unbox() else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Parsed XML number <\(string)> does not fit in \(T.self)."
            ))
        }

        return int
    }

    func unbox<T: BinaryInteger & UnsignedInteger & Decodable>(_ box: XMLContainer) throws -> T {
        let stringBox: XMLStringContainer = try typedBox(box, for: T.self)
        let string = stringBox.unboxed

        guard let uintBox = XMLUIntContainer(xmlString: string) else {
            throw DecodingError.typeMismatch(at: codingPath, expectation: T.self, reality: box)
        }

        guard let uint: T = uintBox.unbox() else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Parsed XML number <\(string)> does not fit in \(T.self)."
            ))
        }

        return uint
    }

    func unbox(_ box: XMLContainer) throws -> Float {
        let stringBox: XMLStringContainer = try typedBox(box, for: Float.self)
        let string = stringBox.unboxed

        guard let floatBox = XMLFloatContainer(xmlString: string) else {
            throw DecodingError.typeMismatch(at: codingPath, expectation: Float.self, reality: box)
        }

        return floatBox.unboxed
    }

    func unbox(_ box: XMLContainer) throws -> Double {
        let stringBox: XMLStringContainer = try typedBox(box, for: Double.self)
        let string = stringBox.unboxed

        guard let doubleBox = XMLDoubleContainer(xmlString: string) else {
            throw DecodingError.typeMismatch(at: codingPath, expectation: Double.self, reality: box)
        }

        return doubleBox.unboxed
    }

    
    func unbox(_ box: XMLContainer) throws -> String {
        do {
            let stringBox: XMLStringContainer = try typedBox(box, for: String.self)
            return stringBox.unboxed
        } catch {
            if box is XMLNullContainer {
                return ""
            }
        }

        return ""
    }
    
    func unbox(_ box: XMLContainer) throws -> URL {
        let stringBox: XMLStringContainer = try typedBox(box, for: URL.self)
        let string = stringBox.unboxed

        guard let urlBox = XMLURLContainer(xmlString: string) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Encountered Data is not valid Base64"
            ))
        }

        return urlBox.unboxed
    }
    
    func unbox(_ box: XMLContainer) throws -> Date {
        switch options.dateDecodingStrategy {
        case .deferredToDate:
            storage.push(container: box)
            defer { storage.popContainer() }
            return try Date(from: self)

        case .secondsSince1970:
            let stringBox: XMLStringContainer = try typedBox(box, for: Date.self)
            let string = stringBox.unboxed

            guard let dateBox = XMLDateContainer(secondsSince1970: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected date string to be formatted in seconds since 1970."
                ))
            }
            return dateBox.unboxed
        case .millisecondsSince1970:
            let stringBox: XMLStringContainer = try typedBox(box, for: Date.self)
            let string = stringBox.unboxed

            guard let dateBox = XMLDateContainer(millisecondsSince1970: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected date string to be formatted in milliseconds since 1970."
                ))
            }
            return dateBox.unboxed
        case .iso8601:
            let stringBox: XMLStringContainer = try typedBox(box, for: Date.self)
            let string = stringBox.unboxed

            guard let dateBox = XMLDateContainer(iso8601: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Expected date string to be ISO8601-formatted."
                ))
            }
            return dateBox.unboxed
        case let .formatted(formatter):
            let stringBox: XMLStringContainer = try typedBox(box, for: Date.self)
            let string = stringBox.unboxed

            guard let dateBox = XMLDateContainer(xmlString: string, formatter: formatter) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "Date string does not match format expected by formatter."
                ))
            }
            return dateBox.unboxed
        case let .custom(closure):
            storage.push(container: box)
            defer { storage.popContainer() }
            return try closure(self)
        }
    }

    func unbox<T: Decodable>(_ box: XMLContainer) throws -> T {
        let decoded: T?
        let type = T.self

        if type == Date.self || type == NSDate.self {
            let date: Date = try unbox(box)
            decoded = date as? T
        } else if type == Data.self || type == NSData.self {
            let data: Data = try unbox(box)
            decoded = data as? T
        } else if type == URL.self || type == NSURL.self {
            let data: URL = try unbox(box)
            decoded = data as? T
        } else if type == Decimal.self || type == NSDecimalNumber.self {
            let decimal: Decimal = try unbox(box)
            decoded = decimal as? T
        } else if
            type == String.self || type == NSString.self,
            let value = (try unbox(box) as String) as? T {
            decoded = value
        } else {
            storage.push(container: box)
            defer {
                storage.popContainer()
            }

            do {
                decoded = try type.init(from: self)
            } catch {
                guard case DecodingError.valueNotFound = error,
                    let type = type as? XMLAnyOptional.Type,
                    let result = type.init() as? T else {
                    throw error
                }

                return result
            }
        }

        guard let result = decoded else {
            throw DecodingError.typeMismatch(
                at: codingPath, expectation: type, reality: box
            )
        }

        return result
    }
}

extension XMLDecoderImplementation {
    var keyTransform: (String) -> String {
        switch options.keyDecodingStrategy {
        case .convertFromSnakeCase:
            return XMLDecoder.KeyDecodingStrategy._convertFromSnakeCase
        case .convertFromCapitalized:
            return XMLDecoder.KeyDecodingStrategy._convertFromCapitalized
        case .convertFromKebabCase:
            return XMLDecoder.KeyDecodingStrategy._convertFromKebabCase
        case .useDefaultKeys:
            return { key in key }
        case let .custom(converter):
            return { key in
                converter(self.codingPath + [XMLKey(stringValue: key, intValue: nil)]).stringValue
            }
        }
    }
}
