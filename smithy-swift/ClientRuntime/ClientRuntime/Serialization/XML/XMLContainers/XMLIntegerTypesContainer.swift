//
//  XMLIntContainer.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//

import Foundation

struct XMLIntContainer: Equatable {
    typealias Unboxed = Int64

    let unboxed: Unboxed

    init<Integer: SignedInteger>(_ unboxed: Integer) {
        self.unboxed = Unboxed(unboxed)
    }

    init?(xmlString: String) {
        guard let unboxed = Unboxed(xmlString) else {
            return nil
        }
        self.init(unboxed)
    }

    func unbox<Integer: BinaryInteger>() -> Integer? {
        return Integer(exactly: unboxed)
    }
}

extension XMLIntContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        return unboxed.description
    }
}

extension XMLIntContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}


struct XMLUIntContainer: Equatable {

    let unboxed: UInt64

    init<Integer: UnsignedInteger>(_ unboxed: Integer) {
        self.unboxed = UInt64(unboxed)
    }

    init?(xmlString: String) {
        guard let unboxed = UInt64(xmlString) else {
            return nil
        }
        self.init(unboxed)
    }

    func unbox<Integer: BinaryInteger>() -> Integer? {
        return Integer(exactly: unboxed)
    }
}

extension XMLUIntContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }
    
    var xmlString: String? {
        return unboxed.description
    }
}

extension XMLUIntContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}

