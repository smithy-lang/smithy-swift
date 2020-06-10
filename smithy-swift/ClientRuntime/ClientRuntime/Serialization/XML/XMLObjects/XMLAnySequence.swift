//
//  XMLAnySequence.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

protocol XMLAnySequence {
    init()
}

extension Array: XMLAnySequence {}

extension Dictionary: XMLAnySequence {}

/// Type-erased protocol helper for a metatype check in generic `decode`
/// overload.
protocol XMLAnyOptional {
    init()
}

extension Optional: XMLAnyOptional {
    init() {
        self = nil
    }
}
