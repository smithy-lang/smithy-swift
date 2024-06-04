//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date

// Base protocol for all identity types
public protocol Identity {
    var expiration: Date? { get }
}
