//
//  XMLDecodingStorage.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

struct XMLDecodingStorage {
    // MARK: Properties

    /// The container stack.
    /// Elements may be any one of the XML types (StringBox, KeyedBox).
    private var containers: [XMLContainer] = []

    // MARK: - Initialization

    /// Initializes `self` with no containers.
    init() {}

    // MARK: - Modifying the Stack

    var count: Int {
        return containers.count
    }

    func topContainer() -> XMLContainer? {
        return containers.last
    }

    mutating func push(container: XMLContainer) {
        if let keyedBox = container as? XMLKeyBasedContainer {
            containers.append(XMLSharedContainer(keyedBox))
        } else if let unkeyedBox = container as? XMLArrayBasedContainer {
            containers.append(XMLSharedContainer(unkeyedBox))
        } else {
            containers.append(container)
        }
    }

    @discardableResult
    mutating func popContainer() -> XMLContainer? {
        guard !containers.isEmpty else {
            return nil
        }
        return containers.removeLast()
    }
}
