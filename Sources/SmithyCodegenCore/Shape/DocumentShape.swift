//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import Smithy

@_spi(SchemaBasedSerde)
public class DocumentShape: Shape, HasMembers {

    public init(id: ShapeID, traits: TraitCollection) {
        super.init(id: id, type: .document, traits: traits)
    }

    var members: [MemberShape] {
        [
            MemberShape(id: .init(id: id, member: "key"), traits: [], targetID: .init("smithy.api", "String")),
            MemberShape(id: .init(id: id, member: "value"), traits: [], targetID: .init("smithy.api", "Document")),
            MemberShape(id: .init(id: id, member: "member"), traits: [], targetID: .init("smithy.api", "Document")),
        ]
    }
}
