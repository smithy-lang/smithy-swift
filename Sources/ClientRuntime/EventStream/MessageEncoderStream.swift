//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Stream adapter that encodes input into `Data` objects.
public protocol MessageEncoderStream: AsyncSequence where Element == Data {
}
