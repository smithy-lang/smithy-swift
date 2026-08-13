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
import class Smithy.HTTPQueryParamsTrait
@_spi(SchemaBasedSerde)
import class Smithy.HTTPQueryTrait
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol Smithy.SchemaExtension
@_spi(SchemaBasedSerde)
import var Smithy.schemaExtensionUniqueIndexCounter

@_spi(SchemaBasedSerde)
public class HTTPBindingsExtension: SchemaExtension {
    public static let uniqueIndex: Int = schemaExtensionUniqueIndexCounter.getNextIndex()

    public let bindings: [HTTPBinding]

    public required init(schema: Schema) throws {
        self.bindings = schema.members.map { member in
            if member.hasTrait(HTTPHeaderTrait.self) {
                return .header
            } else if member.hasTrait(HTTPLabelTrait.self) {
                return .label
            } else if member.hasTrait(HTTPPayloadTrait.self) {
                return .payload
            } else if member.hasTrait(HTTPQueryTrait.self) {
                return .query
            } else if member.hasTrait(HTTPQueryParamsTrait.self) {
                return .queryParams
            } else {
                // If not explicitly bound anywhere else, the member is included in the body
                return .body
            }
        }
    }

}

public enum HTTPBinding {
    case header
    case label
    case payload
    case query
    case queryParams
    case body
}
