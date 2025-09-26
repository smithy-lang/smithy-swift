//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import struct Foundation.TimeInterval
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

public enum DefaultClockSkewProvider {

    @Sendable
    public static func clockSkew(request: HTTPRequest, response: HTTPResponse, error: Error, now: Date) -> TimeInterval? {
        // The default clock skew provider does not determine clock skew.
        return nil
    }
}
