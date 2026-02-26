//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
public protocol Client: Sendable {

    /// This associated type & initializer are for the "old" reference-type config,
    /// and will go away when that config is removed
    associatedtype Config: ClientConfiguration
    init(config: Config)

    /// This associated type & initializer are for the new value-type, Sendable config
    associatedtype Configuration: ClientConfiguration
    init(config: Configuration)

    // Property for accessing the client's config
    var config: Configuration { get }
}
