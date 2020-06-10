//
//  XMLEncodingStorage.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//

import Foundation

// MARK: - Encoding Storage and Containers

struct XMLEncodingStorage {
    // MARK: Properties

    /// The container stack.
    private var containers: [XMLContainer] = []

    // MARK: - Initialization

    /// Initializes `self` with no containers.
    init() {}

    // MARK: - Modifying the Stack

    var count: Int {
        return containers.count
    }

    var lastContainer: XMLContainer? {
        return containers.last
    }

    mutating func pushKeyedContainer(_ keyedBox: XMLKeyBasedContainer = XMLKeyBasedContainer()) -> XMLSharedContainer<XMLKeyBasedContainer> {
        let container = XMLSharedContainer(keyedBox)
        containers.append(container)
        return container
    }

    mutating func pushUnkeyedContainer() -> XMLSharedContainer<XMLArrayBasedContainer> {
        let container = XMLSharedContainer(XMLArrayBasedContainer())
        containers.append(container)
        return container
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

    mutating func popContainer() -> XMLContainer {
        precondition(!containers.isEmpty, "Empty container stack.")
        return containers.popLast()!
    }
}
