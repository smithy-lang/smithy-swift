/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

/// Provides properties for an error that was the result of a response from the service.
public protocol ServiceError {

    /// The type name, if known, for the error that was received.
    var typeName: String? { get }

    /// The message for this error, if one was received.
    var message: String? { get }
}


extension ServiceError {

    /// Returns a localized description for this error, suitable for conformance with Swift `Error`.
    var localizedDescription: String {
        if let message = message {
            return message
        } else if let typeName = typeName {
            return "An error of type \"\(typeName)\" occurred."
        } else {
            return "An unknown error occurred."
        }
    }
}
