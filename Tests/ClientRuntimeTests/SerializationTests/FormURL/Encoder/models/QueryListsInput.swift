//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import ClientRuntime

public struct QueryListsInput: Equatable {
    public let flattenedListArg: [String]?
    public let listArg: [String]?
    
    public init (
        flattenedListArg: [String]? = nil,
        listArg: [String]? = nil
    )
    {
        self.flattenedListArg = flattenedListArg
        self.listArg = listArg
    }
}

extension QueryListsInput: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        if let flattenedListArg = flattenedListArg {
            if flattenedListArg.isEmpty {
                var flattenedListArgContainer = container.nestedUnkeyedContainer(forKey: Key("FlattenedListArg"))
                try flattenedListArgContainer.encodeNil()
            } else {
                for (idx,string0) in flattenedListArg.enumerated() {
                    try container.encode(string0, forKey: Key("FlattenedListArg.\(idx.advanced(by: 1))"))
                }
            }
        }
        if let listArg = listArg {
            var listArgContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("ListArg"))
            for (idx, string0) in listArg.enumerated() {
                try listArgContainer.encode(string0, forKey: Key("member.\(idx.advanced(by: 1))"))
            }
        }
    }
}
