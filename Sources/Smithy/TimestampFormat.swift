//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Custom timestamp serialization formats
/// https://smithy.io/2.0/spec/protocol-traits.html#smithy-api-timestampformat-trait
public enum TimestampFormat: CaseIterable, Sendable {
    /// Also known as Unix time, the number of seconds that have elapsed since 00:00:00 Coordinated Universal Time (UTC), Thursday, 1 January 1970, with optional fractional precision (for example, 1515531081.1234).
    case epochSeconds

    /// Date time as defined by the date-time production in RFC3339 section 5.6 with no UTC offset and optional fractional precision (for example, 1985-04-12T23:20:50.52Z).
    case dateTime

    /// An HTTP date as defined by the IMF-fixdate production in RFC 7231#section-7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT) with optional fractional seconds (for example, Sun, 02 Jan 2000 20:34:56.000 GMT).
    case httpDate
}
