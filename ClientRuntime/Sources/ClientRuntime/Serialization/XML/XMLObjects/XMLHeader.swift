/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLHeader.swift
//  ClientRuntime


import Foundation

public struct XMLHeader {
    /// the XML standard that the produced document conforms to.
    public let version: Double?

    /// the encoding standard used to represent the characters in the produced document.
    public let encoding: String?

    /// indicates whether a document relies on information from an external source.
    public let standalone: String?

    public init(version: Double? = nil, encoding: String? = nil, standalone: String? = nil) {
        self.version = version
        self.encoding = encoding
        self.standalone = standalone
    }

    func isEmpty() -> Bool {
        return version == nil && encoding == nil && standalone == nil
    }

    func toXML() -> String? {
        guard !isEmpty() else {
            return nil
        }

        var string = "<?xml"

        if let version = version {
            string += " version=\"\(version)\""
        }

        if let encoding = encoding {
            string += " encoding=\"\(encoding)\""
        }

        if let standalone = standalone {
            string += " standalone=\"\(standalone)\""
        }

        string += "?>\n"

        return string
    }
}
