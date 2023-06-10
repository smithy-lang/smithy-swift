//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

/// RetryToken is an abstract representation. They encode information for use with subsequent calls to the retry strategy.
/// As such, they’ll likely encode more information using the language type system’s interface extension system such as:
/// TokenBucket, current retry cost, success repayment information, general book-keeping etc...
public protocol RetryToken: AnyObject {

    /// The number of retries (i.e. NOT including the initial attempt) that this token has made.
    var retryCount: Int { get }

    /// The delay for this request (TODO: not used)
    var delay: TimeInterval? { get }
}
