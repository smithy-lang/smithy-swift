/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLAnySequence.swift
//  XMLParser

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
