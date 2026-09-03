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

    /// The parts of the HTTP request that this schema's members are bound to.
    ///
    /// A serializer for a part that appears here is needed; one for any other part would have nothing
    /// to serialize, so it is never created.
    public let boundParts: Set<HTTPBinding>

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
        self.boundParts = Set(self.bindings)
    }

}

public enum HTTPBinding: Hashable, Sendable {
    case header
    case label
    case payload
    case prefixHeaders
    case query
    case queryParams
    case responseCode
    case body
}
