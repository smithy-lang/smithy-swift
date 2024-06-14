//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// `WaiterOutcome` is returned after waiting ends successfully.  The `attempts`
/// field indicates how many attempts to poll the resource were needed for the wait to succeed, and
/// the `result` field contains the result of the operation that caused the wait
/// to succeed.  Note that a waiter can succeed on an error if its is configured that way.
///
/// In the case of an failed wait, waiting ends by throwing an error instead of
/// returning a `WaiterOutcome`.
public struct WaiterOutcome<Output> {

    /// The number of operation attempts that were required for the wait to succeed.
    public let attempts: Int

    /// The result (output object or error) that caused an `Acceptor` to match.
    public let result: Result<Output, Error>

    /// Creates an instance of WaiterOutcome
    /// - Parameter attempts: The number of operation attempts that were required for the wait to succeed.
    /// - Parameter result: The result (output object or error) that caused an `Acceptor` to match.
    public init(attempts: Int, result: Result<Output, Error>) {
        self.attempts = attempts
        self.result = result
    }
}
