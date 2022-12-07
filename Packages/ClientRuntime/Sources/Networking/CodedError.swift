/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public protocol CodedError: Error {

    /// The `String` error code that identifies the general type of this HTTP service error, or `nil` if the
    /// error has no known code.
    ///
    /// The source of this code is the HTTP response to an API call, but what exact header, body field, etc.
    /// it comes from is specific to the response encoding used.
    var errorCode: String? { get }
}
