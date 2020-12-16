/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLSimpleKeyBasedContainer.swift
//  XMLParser

import Foundation

struct XMLSimpleKeyBasedContainer: XMLSimpleContainer {
    var key: String
    var element: XMLContainer

    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        return nil
    }
}
