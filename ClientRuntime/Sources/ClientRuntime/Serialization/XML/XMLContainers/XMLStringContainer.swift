//
//  XMLStringContainer.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

struct XMLStringContainer: Equatable {

    let unboxed: String

    init(_ unboxed: String) {
        self.unboxed = unboxed
    }

    init(xmlString: String) {
        self.init(xmlString)
    }
}

extension XMLStringContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        return unboxed.description
    }
}

extension XMLStringContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}
