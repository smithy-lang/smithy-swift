/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLNullContainer.swift
//  XMLParser

import Foundation

struct XMLNullContainer: XMLSimpleContainer {

    var isNull: Bool {
        return true
    }

    var xmlString: String? {
        return nil
    }
}

extension XMLNullContainer: Equatable {
    static func == (_: XMLNullContainer, _: XMLNullContainer) -> Bool {
        return true
    }
}

extension XMLNullContainer: CustomStringConvertible {
    var description: String {
        return "null"
    }
}
