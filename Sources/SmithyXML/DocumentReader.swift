//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import typealias SmithyReadWrite.ReadingClosure
import enum SmithyReadWrite.DocumentError

public enum DocumentReader {

    static func read<T>(_ data: Data, readingClosure: ReadingClosure<T, Reader>) throws -> T {
        let reader = try Reader.from(data: data)
        if let value = try readingClosure(reader) {
            return value
        } else {
            throw DocumentError.requiredValueNotPresent
        }
    }
}
