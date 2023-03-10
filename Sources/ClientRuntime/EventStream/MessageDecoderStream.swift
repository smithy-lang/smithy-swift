//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Stream adapter that decodes input data into `EventStream.Message` objects.
public protocol MessageDecoderStream: AsyncSequence where Element == EventStream.Message {
}
