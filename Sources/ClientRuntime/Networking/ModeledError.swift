//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Indicates whether the fault for a modeled error is on the client or server.
public enum ErrorFault {

    /// The error is the fault of the client (i.e. a bad request.)
    case client

    /// The error is the fault of the server (i.e. unhandled exception, not available, etc.)
    case server
}

/// Provides information about a type of modeled error.
///
/// The properties of `ModeledError` are determined by the Smithy definition of the error type.
public protocol ModeledError {

    /// The name of this error, without the Smithy namespace.
    ///
    /// Will most often be the same as the name of the Swift error type.
    static var typeName: String { get }

    /// Whether this type of error is considered to be the fault of the server or client.
    static var fault: ErrorFault { get }

    /// Whether this error is defined as retryable.
    static var isRetryable: Bool { get }

    /// Whether this error indicates that the server is throttling requests.
    ///
    /// Will be `false` when `isRetryable` is also false.
    static var isThrottling: Bool { get }
}

extension ModeledError {

    /// Provides the modeled error's type name as a instance property.
    ///
    /// Provided to allow for conformance with `ServiceError`.
    public var typeName: String? { Self.typeName }
}
