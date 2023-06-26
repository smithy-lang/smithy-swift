/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// General networking protocol independent service error structure.
///
/// Used when exact error could not be deduced during deserialization.
public struct UnknownServiceError: ServiceError, Error {

    /// The type name, if known, for the error that was received.
    public var typeName: String?

    /// The message for this error, if one was received.
    public var message: String?

    public init(typeName: String?, message: String?) {
        self.typeName = typeName
        self.message = message
    }
}
