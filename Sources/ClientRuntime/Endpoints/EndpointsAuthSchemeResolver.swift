//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyHTTPAPI.EndpointPropertyValue

/// Supported authentication schemes
public enum EndpointsAuthScheme: Equatable {
    case sigV4(SigV4Parameters)
    case sigV4A(SigV4AParameters)
    case sigV4S3Express(SigV4Parameters)
    case none

    /// The name of the auth scheme
    public var name: String {
        switch self {
        case .sigV4: return "sigv4"
        case .sigV4A: return "sigv4a"
        case .sigV4S3Express: return "sigv4-s3express"
        case .none: return "none"
        }
    }
}

extension EndpointsAuthScheme {
    /// Initialize an AuthScheme from a dictionary
    /// - Parameter dictionary: Dictionary containing the auth scheme
    public init(from dictionary: [String: Any]) throws {
        guard let endpointProperty = dictionary["name"] as? SmithyHTTPAPI.EndpointPropertyValue,
              case let .string(name) = endpointProperty else {
            throw EndpointError.authScheme("Invalid auth scheme")
        }
        switch name {
        case "sigv4":
            self = .sigV4(try SigV4Parameters(from: dictionary))
        case "sigv4a":
            self = .sigV4A(try SigV4AParameters(from: dictionary))
        case "sigv4-s3express":
            self = .sigV4S3Express(try SigV4Parameters(from: dictionary))
        case "none":
            self = .none
        default:
            throw EndpointError.authScheme("Unknown auth scheme \(name)")
        }
    }
}

extension EndpointsAuthScheme {
    /// SigV4 auth scheme
    public struct SigV4Parameters: Equatable {

        /// Service name to use for signing
        public let signingName: String?

        /// Region to use for signing
        public let signingRegion: String?

        /// When true, do not double-escape path during signing
        public let disableDoubleEncoding: Bool?
    }
}

extension EndpointsAuthScheme.SigV4Parameters {
    /// Initialize a SigV4AuthScheme from a dictionary
    /// - Parameter dictionary: Dictionary containing the auth scheme
    init(from dictionary: [String: Any]) throws {
        // For signingName (expected to be a string)
        if let value = dictionary["signingName"] as? EndpointPropertyValue,
           case let .string(name) = value {
            self.signingName = name
        } else {
            self.signingName = nil
        }

        // For signingRegion (expected to be a string)
        if let value = dictionary["signingRegion"] as? EndpointPropertyValue,
           case let .string(region) = value {
            self.signingRegion = region
        } else {
            self.signingRegion = nil
        }

        // For disableDoubleEncoding (expected to be a bool)
        if let value = dictionary["disableDoubleEncoding"] as? EndpointPropertyValue,
           case let .bool(flag) = value {
            self.disableDoubleEncoding = flag
        } else {
            self.disableDoubleEncoding = nil
        }
    }
}

extension EndpointsAuthScheme {
    /// SigV4a auth scheme
    public struct SigV4AParameters: Equatable {

        /// Service name to use for signing
        public let signingName: String?

        /// The set of signing regions to use for this endpoint. Currently,
        /// this will always be ["*"].
        public let signingRegionSet: [String]?

        /// When true, do not double-escape path during signing
        public let disableDoubleEncoding: Bool?
    }
}

extension EndpointsAuthScheme.SigV4AParameters {
    /// Initialize a SigV4AAuthScheme from a dictionary
    /// - Parameter dictionary: Dictionary containing the auth scheme
    init(from dictionary: [String: Any]) throws {
        // Extract signingName
        if let value = dictionary["signingName"] as? EndpointPropertyValue,
           case let .string(name) = value {
            self.signingName = name
        } else {
            self.signingName = nil
        }

        // Extract signingRegionSet as an array of String
        if let value = dictionary["signingRegionSet"] as? EndpointPropertyValue,
           case let .array(regions) = value {
            self.signingRegionSet = regions.compactMap { element in
                if case let .string(region) = element {
                    return region
                }
                return nil
            }
        } else {
            self.signingRegionSet = nil
        }

        // Extract disableDoubleEncoding
        if let value = dictionary["disableDoubleEncoding"] as? EndpointPropertyValue,
           case let .bool(flag) = value {
            self.disableDoubleEncoding = flag
        } else {
            self.disableDoubleEncoding = nil
        }
    }
}

/// Resolves the auth scheme to use for a given endpoint
public protocol EndpointsAuthSchemeResolver {

    /// Resolves the auth scheme to use for a given endpoint
    /// If no auth scheme is supported, returns nil and the SDK must throw an error
    /// - Parameter authSchemes: auth schemes to resolve
    /// - Returns: Auth scheme to use
    func resolve(authSchemes: [EndpointsAuthScheme]) throws -> EndpointsAuthScheme
}

/// Default implementation of AuthSchemeResolver
public struct DefaultEndpointsAuthSchemeResolver: EndpointsAuthSchemeResolver {

    /// Supported auth schemes by the SDK
    let supportedAuthSchemes: Set<String>

    public init(supportedAuthSchemes: Set<String> = ["sigv4", "sigv4a", "sigv4-s3express", "none"]) {
        self.supportedAuthSchemes = supportedAuthSchemes
    }

    public func resolve(authSchemes: [EndpointsAuthScheme]) throws -> EndpointsAuthScheme {
        guard let authScheme = authSchemes.first(where: { supportedAuthSchemes.contains($0.name) }) else {
            throw EndpointError.authScheme("Failed to resolve auth scheme. Supported schemes: \(supportedAuthSchemes),"
                                           + "available schemes: \(authSchemes.map { $0.name })")
        }

        return authScheme
    }
}
