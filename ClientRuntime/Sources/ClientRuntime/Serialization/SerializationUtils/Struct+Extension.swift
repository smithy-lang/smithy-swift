/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import Foundation

public protocol Reflection {
    func allPropertiesAreNull() throws -> Bool
}

public extension Reflection {
    func allPropertiesAreNull() throws -> Bool {

        let mirror = Mirror(reflecting: self)

        return mirror.children.filter {
            if case Optional<Any>.some(_) = $0.value {
                   return false
               } else {
                   return true
               }
        }.count == mirror.children.count
    }
}
