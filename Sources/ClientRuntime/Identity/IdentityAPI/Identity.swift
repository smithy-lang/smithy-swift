//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Base protocol for all identity types
public protocol Identity {
    var expiration: Date? { get }
}

// Enum of identity types supported by SDK
public enum IdentityType: CaseIterable {
    case aws
}
