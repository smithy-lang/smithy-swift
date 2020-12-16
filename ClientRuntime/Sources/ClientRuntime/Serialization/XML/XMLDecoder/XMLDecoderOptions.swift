//
//  XMLDecoderOptions.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//

import Foundation

/// Options set on the top-level encoder to pass down the Decoding hierarchy.
public struct XMLDecoderOptions {
    var dateDecodingStrategy: XMLDecoder.DateDecodingStrategy = .deferredToDate
    var dataDecodingStrategy: XMLDecoder.DataDecodingStrategy = .base64
    var nonConformingFloatDecodingStrategy: XMLDecoder.NonConformingFloatDecodingStrategy = .throw
    var keyDecodingStrategy: XMLDecoder.KeyDecodingStrategy = .useDefaultKeys
    var nodeDecodingStrategy: XMLDecoder.NodeDecodingStrategy = .deferredToDecoder
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var errorContextLength: UInt = 0
    var shouldProcessNamespaces: Bool = false
    var trimValueWhitespaces: Bool = true

    public init(dateDecodingStrategy: XMLDecoder.DateDecodingStrategy = .deferredToDate,
                dataDecodingStrategy: XMLDecoder.DataDecodingStrategy = .base64,
                nonConformingFloatDecodingStrategy: XMLDecoder.NonConformingFloatDecodingStrategy = .throw,
                keyDecodingStrategy: XMLDecoder.KeyDecodingStrategy = .useDefaultKeys,
                nodeDecodingStrategy: XMLDecoder.NodeDecodingStrategy = .deferredToDecoder,
                userInfo: [CodingUserInfoKey: Any] = [:],
                errorContextLength: UInt = 0,
                shouldProcessNamespaces: Bool = false,
                trimValueWhitespaces: Bool = true) {
        self.dateDecodingStrategy = dateDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy
        self.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
        self.keyDecodingStrategy = keyDecodingStrategy
        self.nodeDecodingStrategy = nodeDecodingStrategy
        self.userInfo = userInfo
        self.errorContextLength = errorContextLength
        self.shouldProcessNamespaces = shouldProcessNamespaces
        self.trimValueWhitespaces = trimValueWhitespaces
    }
}
