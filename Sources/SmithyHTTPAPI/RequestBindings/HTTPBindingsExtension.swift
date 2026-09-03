//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.HTTPHeaderTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPLabelTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPPayloadTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPPrefixHeadersTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPQueryParamsTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPQueryTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPResponseCodeTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter
import enum Smithy.ShapeType

@_spi(SchemaBasedSerde)
public final class HTTPBindingsExtension: SchemaExtension {
    public static let uniqueIndex: Int = schemaExtensionUniqueIndexCounter.getNextIndex()

    public let bindings: [HTTPBinding]

    public let payloadType: ShapeType?

    /// Whether any member of the schema is bound to each part of the HTTP request.
    ///
    /// A serializer is created only for a part that some member is bound to; one for any other part
    /// would have nothing to serialize.  These are resolved once here, since testing them against
    /// ``bindings`` on every request would search it repeatedly.
    public let hasHeaderBinding: Bool
    public let hasPrefixHeadersBinding: Bool
    public let hasQueryBinding: Bool
    public let hasQueryParamsBinding: Bool
    public let hasPayloadBinding: Bool
    public let hasBodyBinding: Bool

    public required init(schema: Schema) throws {
        var payloadType: ShapeType?
        self.bindings = schema.members.map { member in
            if member.hasTrait(HTTPHeaderTrait.self) {
                return .header
            } else if member.hasTrait(HTTPPrefixHeadersTrait.self) {
                return .prefixHeaders
            } else if member.hasTrait(HTTPLabelTrait.self) {
                return .label
            } else if member.hasTrait(HTTPPayloadTrait.self) {
                payloadType = member.type
                return .payload
            } else if member.hasTrait(HTTPQueryTrait.self) {
                return .query
            } else if member.hasTrait(HTTPQueryParamsTrait.self) {
                return .queryParams
            } else if member.hasTrait(HTTPResponseCodeTrait.self) {
                return .responseCode
            } else {
                // If not explicitly bound anywhere else, the member is included in the body
                return .body
            }
        }
        self.payloadType = payloadType
        self.hasHeaderBinding = self.bindings.contains { $0 == .header }
        self.hasPrefixHeadersBinding = self.bindings.contains { $0 == .prefixHeaders }
        self.hasQueryBinding = self.bindings.contains { $0 == .query }
        self.hasQueryParamsBinding = self.bindings.contains { $0 == .queryParams }
        self.hasPayloadBinding = self.bindings.contains { $0 == .payload }
        self.hasBodyBinding = self.bindings.contains { $0 == .body }
    }

}

public enum HTTPBinding: Sendable {
    case header
    case label
    case payload
    case prefixHeaders
    case query
    case queryParams
    case responseCode
    case body
}
