//
//  XMLFloatContainer.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//

import Foundation

struct XMLFloatContainer: Equatable, XMLValueContainer {
    typealias Unboxed = Float

    let unboxed: Unboxed

    init<Float: BinaryFloatingPoint>(_ unboxed: Float) {
        self.unboxed = Unboxed(unboxed)
    }

    init?(xmlString: String) {
        guard let unboxed = Unboxed(xmlString) else {
            return nil
        }
        self.init(unboxed)
    }
}

extension XMLFloatContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        guard !unboxed.isNaN else {
            return "NaN"
        }

        guard !unboxed.isInfinite else {
            return (unboxed > 0.0) ? "INF" : "-INF"
        }

        return unboxed.description
    }
}

extension XMLFloatContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}


struct XMLDecimalContainer: Equatable {

    let unboxed: Decimal

    init(_ unboxed: Decimal) {
        self.unboxed = unboxed
    }

    init?(xmlString: String) {
        guard let unboxed = Decimal(string: xmlString) else {
            return nil
        }
        self.init(unboxed)
    }
}

extension XMLDecimalContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        return "\(unboxed)"
    }
}

extension XMLDecimalContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}


struct XMLDoubleContainer: Equatable, XMLValueContainer {

    let unboxed: Double

    init(_ value: Double) {
        unboxed = value
    }

    init?(xmlString: String) {
        guard let unboxed = Double(xmlString) else { return nil }

        self.init(unboxed)
    }
}

extension XMLDoubleContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        guard !unboxed.isNaN else {
            return "NaN"
        }

        guard !unboxed.isInfinite else {
            return (unboxed > 0.0) ? "INF" : "-INF"
        }

        return unboxed.description
    }
}

extension XMLDoubleContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}
