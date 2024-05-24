//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

/// Decodes a `Data` object into a `Message` object.
public protocol MessageDecoder {

    /// Feeds data into the decoder, which may or may not result in a message.
    /// - Parameter data: The data to feed into the decoder.
    func feed(data: Data) throws

    /// Notifies the decoder that the stream has ended.
    /// It may throw an error if the stream is not in a valid state.
    func endOfStream() throws

    /// Returns the next message in the decoder's buffer
    /// and removes it from the buffer.
    func message() throws -> Message?
}
