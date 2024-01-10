//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import typealias SmithyReadWrite.ReadingClosure
import enum SmithyTimestamps.TimestampFormat

public func mapReadingClosure<T>(
    valueReadingClosure: @escaping ReadingClosure<T, Reader>,
    keyNodeInfo: NodeInfo,
    valueNodeInfo: NodeInfo,
    isFlattened: Bool
) -> ReadingClosure<[String: T], Reader> {
    return { reader in
        try reader.readMapIfPresent(
            valueReadingClosure: valueReadingClosure,
            keyNodeInfo: keyNodeInfo,
            valueNodeInfo: valueNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func listReadingClosure<T>(
    memberReadingClosure: @escaping ReadingClosure<T, Reader>,
    memberNodeInfo: NodeInfo,
    isFlattened: Bool
) -> ReadingClosure<[T], Reader> {
    return { reader in
        try reader.readListIfPresent(
            memberReadingClosure: memberReadingClosure,
            memberNodeInfo: memberNodeInfo,
            isFlattened: isFlattened
        )
    }
}

public func timestampReadingClosure(format: TimestampFormat) -> ReadingClosure<Date, Reader> {
    return { reader in
        try reader.readTimestampIfPresent(format: format)
    }
}

public extension String {

    static var readingClosure: ReadingClosure<String, Reader> {
        return { reader in
            try reader.readIfPresent()
        }
    }
}

public extension RawRepresentable where RawValue == Int {

    static var readingClosure: ReadingClosure<Self, Reader> {
        return { reader in
            try reader.readIfPresent()
        }
    }
}

public extension RawRepresentable where RawValue == String {

    static var readingClosure: ReadingClosure<Self, Reader> {
        return { reader in
            try reader.readIfPresent()
        }
    }
}

public extension Bool {

    static var readingClosure: ReadingClosure<Bool, Reader> {
        return { reader in
            try reader.readIfPresent()
        }
    }
}

public extension Int {

    static var readingClosure: ReadingClosure<Int, Reader> {
        return { reader in
            try reader.readIfPresent()
        }
    }
}

public extension Float {

    static var readingClosure: ReadingClosure<Float, Reader> {
        return { reader in
            try reader.readIfPresent()
        }
    }
}

public extension Double {

    static var readingClosure: ReadingClosure<Double, Reader> {
        return { reader in
            try reader.readIfPresent()
        }
    }
}
