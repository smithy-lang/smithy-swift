//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

/// Encodes a `Message` into a `Data` object
/// to be sent over the wire.
public protocol MessageEncoder: Sendable {

    /// Encodes a `Message` into a `Data` object
    func encode(message: Message) throws -> Data
}
