//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AWSChunkedStream {
    func getChunkedReader() -> AWSChunkedReader
    var checksumAlgorithm: ChecksumAlgorithm? { get set }
}
