//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyFormURL
@testable import ClientRuntime

public struct QueryMapsInput: Equatable {
    public let flattenedMap: [String:String]?
    public let mapArg: [String:String]?

    public init (
        flattenedMap: [String:String]? = nil,
        mapArg: [String:String]? = nil
    )
    {
        self.flattenedMap = flattenedMap
        self.mapArg = mapArg
    }
}

extension QueryMapsInput: Encodable {

    static func write(value: QueryMapsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["FlattenedMap"].writeMap(value.flattenedMap, valueWritingClosure: String.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: true)
        try writer["MapArg"].writeMap(value.mapArg, valueWritingClosure: String.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
