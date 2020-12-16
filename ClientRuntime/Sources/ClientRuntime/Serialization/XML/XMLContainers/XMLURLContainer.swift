//
//  XMLURLContainer.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//

import Foundation

struct XMLURLContainer: Equatable {

    let unboxed: URL

    init(_ unboxed: URL) {
        self.unboxed = unboxed
    }

    init?(xmlString: String) {
        guard let unboxed = URL(string: xmlString) else {
            return nil
        }
        self.init(unboxed)
    }
}

extension XMLURLContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        return unboxed.absoluteString
    }
}

extension XMLURLContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}
