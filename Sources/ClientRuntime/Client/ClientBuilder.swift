//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
public class ClientBuilder<ClientType: Client> {
    private var config: ClientType.Configuration?
    private var plugins = [any Plugin]()

    public init(defaultPlugins: [any Plugin] = []) {
        self.plugins = defaultPlugins
    }

    public func withConfig(_ config: ClientType.Configuration) -> Self {
        self.config = config
        return self
    }

    public func withPlugin(_ plugin: any Plugin) -> ClientBuilder<ClientType> {
        self.plugins.append(plugin)
        return self
    }

    public func withPlugins(_ plugins: [any Plugin]) -> ClientBuilder<ClientType> {
        self.plugins.append(contentsOf: plugins)
        return self
    }

    public func build() async throws -> ClientType {
        let configuration = try await resolve(plugins: self.plugins)
        return ClientType(config: configuration)
    }

    private func resolve(plugins: [any Plugin]) async throws -> ClientType.Configuration {
        var clientConfiguration: ClientType.Configuration
        if let config {
            clientConfiguration = config
        } else {
            clientConfiguration = try await ClientType.Configuration()
        }
        for plugin in plugins {
            try await plugin.configureClient(clientConfiguration: &clientConfiguration)
        }
        return clientConfiguration
    }
}
