//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class ClientBuilder<ClientType: Client> {

    private struct PluginContainer: Plugin {
        let plugin: any Plugin<ClientType.Config>

        func configureClient(clientConfiguration: inout ClientType.Config) async throws {
            try await plugin.configureClient(clientConfiguration: &clientConfiguration)
        }
    }

    private var plugins = [PluginContainer]()

    public init() {}

    public func withPlugin<P: Plugin>(_ plugin: P) -> ClientBuilder<ClientType> where P.Config == ClientType.Config {
        self.plugins.append(PluginContainer(plugin: plugin))
        return self
    }

    public func build() async throws -> ClientType {
        let configuration = try await resolve()
        return ClientType(config: configuration)
    }

    private func resolve() async throws -> ClientType.Config {
        var config = try await ClientType.Config()
        for plugin in plugins {
            try await plugin.configureClient(clientConfiguration: &config)
        }
        return config
    }
}
