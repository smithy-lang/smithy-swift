/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

/// Options set on the top-level encoder to pass down the encoding hierarchy.
public struct XMLEncoderOptions {
    var dateEncodingStrategy: XMLEncoder.DateEncodingStrategy = .deferredToDate
    var dataEncodingStrategy: XMLEncoder.DataEncodingStrategy = .base64
    var nonConformingFloatEncodingStrategy: XMLEncoder.NonConformingFloatEncodingStrategy = .throw
    var keyEncodingStrategy: XMLEncoder.KeyEncodingStrategy = .useDefaultKeys
    var nodeEncodingStrategy: XMLEncoder.NodeEncodingStrategy = .deferredToEncoder
    var stringEncodingStrategy: XMLEncoder.StringEncodingStrategy = .deferredToString
    var outputFormatting: XMLEncoder.OutputFormatting = .sortedKeys
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var rootKey: String?
    var rootAttributes: [String: String]?
    var header: XMLHeader?

    public init(dateEncodingStrategy: XMLEncoder.DateEncodingStrategy = .deferredToDate,
                dataEncodingStrategy: XMLEncoder.DataEncodingStrategy = .base64,
                nonConformingFloatEncodingStrategy: XMLEncoder.NonConformingFloatEncodingStrategy = .throw,
                keyEncodingStrategy: XMLEncoder.KeyEncodingStrategy = .useDefaultKeys,
                nodeEncodingStrategy: XMLEncoder.NodeEncodingStrategy = .deferredToEncoder,
                stringEncodingStrategy: XMLEncoder.StringEncodingStrategy = .deferredToString,
                outputFormatting: XMLEncoder.OutputFormatting = .sortedKeys,
                userInfo: [CodingUserInfoKey: Any] = [:],
                rootKey: String? = nil,
                rootAttributes: [String: String]? = nil,
                header: XMLHeader? = nil) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.dataEncodingStrategy = dataEncodingStrategy
        self.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
        self.nodeEncodingStrategy = nodeEncodingStrategy
        self.stringEncodingStrategy = stringEncodingStrategy
        self.outputFormatting = outputFormatting
        self.userInfo = userInfo
        self.rootKey = rootKey
        self.rootAttributes = rootAttributes
        self.header = header
    }
}
