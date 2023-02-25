//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

public protocol ReadableStream: AnyObject {
    var position: Data.Index { get }
    var length: Int? { get }
    var isEmpty: Bool { get }
    func read(upToCount count: Int) throws -> Data?
    func readToEnd() throws -> Data?
    func seek(toOffset offset: Int) throws
}

public protocol WriteableStream: AnyObject {
    func write(contentsOf data: Data) throws
    func close() throws
}

public protocol Stream: ReadableStream, WriteableStream {
}
