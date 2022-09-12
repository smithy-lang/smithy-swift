/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import SmithyClientRuntime

public struct QueryIdempotencyTestTokenGenerator: IdempotencyTokenGenerator {
    public init() {}
    public func generateToken() -> String {
        return "00000000-0000-4000-8000-000000000000"
    }
}
