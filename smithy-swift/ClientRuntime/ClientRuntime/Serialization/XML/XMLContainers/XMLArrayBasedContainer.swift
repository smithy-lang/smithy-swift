//
//  XMLArrayBasedContainer.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

typealias XMLArrayBasedContainer = [XMLContainer]

extension Array: XMLContainer {
    var isNull: Bool {
        return false
    }
    
    var xmlString: String? {
        return nil
    }
}
