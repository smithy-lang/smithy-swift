//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import struct Foundation.TimeInterval
import protocol Smithy.RequestMessage
import protocol Smithy.ResponseMessage

public enum DefaultClockSkewProvider {

    public static func provider<Request: RequestMessage, Response: ResponseMessage>(
    ) -> ClockSkewProvider<Request, Response> {
        return clockSkew(request:response:error:previous:)
    }

    @Sendable
    private static func clockSkew<Request: RequestMessage, Response: ResponseMessage>(
        request: Request,
        response: Response,
        error: Error,
        previous: TimeInterval?
    ) -> TimeInterval? {
        // The default clock skew provider does not determine clock skew.
        return nil
    }
}
