//
//  XMLSimpleKeyBasedContainer.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

struct XMLSimpleKeyBasedContainer: XMLSimpleContainer {
    var key: String
    var element: XMLContainer
    
    var isNull: Bool {
        return false
    }
    
    var xmlString: String? {
        return nil
    }
}
