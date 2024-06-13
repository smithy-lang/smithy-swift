//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyReadWrite
import SmithyFormURL
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

extension QueryListsInput {

    static func write(value: QueryListsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["FlattenedListArg"].writeList(value.flattenedListArg, memberWritingClosure: WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: true)
        try writer["ListArg"].writeList(value.listArg, memberWritingClosure: WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
