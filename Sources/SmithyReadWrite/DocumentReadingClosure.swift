//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public typealias DocumentReadingClosure<T, Reader> = (Data, ReadingClosure<T, Reader>) throws -> T

public func documentReadingClosure<T, Reader: SmithyReader>(
    rootNodeInfo: Reader.NodeInfo
) -> DocumentReadingClosure<T, Reader> {
    return { data, readingClosure in
        try DocumentReader.read(data, readingClosure: readingClosure)
    }
}

public enum DocumentError: Error {
    case requiredValueNotPresent
}
