//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import struct Foundation.TimeInterval

public typealias ClockSkewProvider<Request, Response> = @Sendable (Request, Response, Error, Date) -> TimeInterval?
