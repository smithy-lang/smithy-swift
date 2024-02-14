//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
public class ClientBuilder<ClientType: Client> {

    private var plugins: [Plugin]

    public init(defaultPlugins: [Plugin] = []) {
        self.plugins = defaultPlugins
    }

    public func withPlugin(_ plugin: any Plugin) -> ClientBuilder<ClientType> {
        self.plugins.append(plugin)
        return self
    }

    public func build() async throws -> ClientType {
        let configuration = try await resolve(plugins: self.plugins)
        return ClientType(config: configuration)
    }

    func resolve(plugins: [any Plugin]) async throws -> ClientType.Config {
        let clientConfiguration = try await ClientType.Config()
        for plugin in plugins {
            try await plugin.configureClient(clientConfiguration: clientConfiguration)
        }
        return clientConfiguration
    }
}
