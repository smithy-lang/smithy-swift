//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors that may be thrown when an operation is retried unsuccessfully.
public enum RetryError: Error {

    /// The maximum number of allowed retry attempts were made,
    /// but the operation could not be successfully completed.
    case maxAttemptsReached
}
