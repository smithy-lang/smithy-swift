//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import struct Smithy.Attributes

// Base protocol for all identity types
public protocol Identity: Sendable {
    var expiration: Date? { get }
    var properties: Attributes { get }
}
