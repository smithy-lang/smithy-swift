/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLArrayBasedContainer.swift
//  XMLParser

import Foundation

typealias XMLArrayBasedContainer = [XMLContainer]

extension Array: XMLContainer {
    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        return nil
    }
}
