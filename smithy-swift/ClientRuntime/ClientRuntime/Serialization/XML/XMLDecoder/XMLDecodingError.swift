//
//  XMLDecodingError.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

extension DecodingError {
    
    static func typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: XMLContainer) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(_typeDescription(of: reality)) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }

    static func _typeDescription(of box: XMLContainer) -> String {
        switch box {
        case is XMLNullContainer:
            return "a null value"
        case is XMLArrayBasedContainer:
            return "a array value"
        case is XMLKeyBasedContainer:
            return "a dictionary value"
        case _:
            return "\(type(of: box))"
        }
    }
}
