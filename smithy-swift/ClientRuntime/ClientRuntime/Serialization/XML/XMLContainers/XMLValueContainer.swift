//
//  XMLValueContainer.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//

import Foundation

protocol XMLValueContainer: XMLSimpleContainer {
    associatedtype Unboxed

    init(_ value: Unboxed)
}
