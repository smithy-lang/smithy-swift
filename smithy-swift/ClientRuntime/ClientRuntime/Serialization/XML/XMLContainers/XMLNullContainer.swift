//
//  XMLNullContainer.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

struct XMLNullContainer: XMLSimpleContainer {
    
    var isNull: Bool {
        return true
    }
    
    var xmlString: String? {
        return nil
    }
}

extension XMLNullContainer: Equatable {
    static func ==(_: XMLNullContainer, _: XMLNullContainer) -> Bool {
        return true
    }
}

extension XMLNullContainer: CustomStringConvertible {
    var description: String {
        return "null"
    }
}
