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

    enum ClientBuilderError: Error {
        case incompatibleConfigurationType(expected: String, received: String)
    }

    func resolve(plugins: [any Plugin]) async throws -> ClientType.Config {
        var clientConfiguration: any ClientConfiguration = try await ClientType.Config()
        for plugin in plugins {
            try await plugin.configureClient(clientConfiguration: &clientConfiguration)
        }
        guard let typedConfig = clientConfiguration as? ClientType.Config else {
            throw ClientBuilderError.incompatibleConfigurationType(
                expected: String(describing: ClientType.Config.self),
                received: String(describing: type(of: clientConfiguration))
            )
        }
        return typedConfig
    }
}
