//
//  XMLSharedContainer.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

class XMLSharedContainer<ContainerType: XMLContainer>: XMLContainer {

    private(set) var unboxed: ContainerType

    init(_ wrapped: ContainerType) {
        unboxed = wrapped
    }

    var isNull: Bool {
        return unboxed.isNull
    }

    var xmlString: String? {
        return unboxed.xmlString
    }

    func withShared<T>(_ xmlContainer: (inout ContainerType) throws -> T) rethrows -> T {
        return try xmlContainer(&unboxed)
    }
}

extension XMLSharedContainer: XMLSharedContainerProtocol {
    func unbox() -> XMLContainer {
        return unboxed
    }

    func unbox() -> ContainerType {
        return unboxed
    }
}
