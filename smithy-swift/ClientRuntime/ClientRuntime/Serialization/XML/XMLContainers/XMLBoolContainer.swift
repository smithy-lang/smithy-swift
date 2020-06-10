//
//  XMLBoolContainer.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//

import Foundation

struct XMLBoolContainer: Equatable {

    let unboxed: Bool

    init(_ unboxed: Bool) {
        self.unboxed = unboxed
    }

    init?(xmlString: String) {
        switch xmlString.lowercased() {
        case "false", "0", "n", "no": self.init(false)
        case "true", "1", "y", "yes": self.init(true)
        case _: return nil
        }
    }
}

extension XMLBoolContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }
    
    var xmlString: String? {
        return (unboxed) ? "true" : "false"
    }
}

extension XMLBoolContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}
