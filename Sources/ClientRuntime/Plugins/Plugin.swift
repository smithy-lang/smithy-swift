//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol Plugin<Config> {
    associatedtype Config: ClientConfiguration

    func configureClient(clientConfiguration: Config) async throws -> Config
}
