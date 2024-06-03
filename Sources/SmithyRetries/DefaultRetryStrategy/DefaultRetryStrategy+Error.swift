//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension DefaultRetryStrategy {

    /// Errors that may be thrown when an operation is retried unsuccessfully.
    enum Error: Swift.Error {

        /// The number and frequency of retries being attempted has exceeded the
        /// current limits.
        ///
        /// This error is only raised when the `adaptive` rate limiting mode of retry is used.
        case insufficientQuota
    }
}
