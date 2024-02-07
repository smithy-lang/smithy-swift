//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AwsChunkedStream {
    func getChunkedReader() -> AwsChunkedReader
    var checksumAlgorithm: HashFunction? { get set }
}
