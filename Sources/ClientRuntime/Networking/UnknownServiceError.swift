/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// General networking protocol independent service error structure used when exact error
/// could not be deduced during deserialization
public struct UnknownServiceError: ServiceError {
    public var typeName: String?
    public var message: String?

    public init(typeName: String?, message: String?) {
        self.message = message
    }
}
