//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum ExponentialBackOffJitterType: Sendable {
    case `default`
    case none
    case full
    case decorrelated
}
