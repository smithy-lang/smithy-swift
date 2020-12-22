/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public struct DefaultIdempotencyTokenGenerator: IdempotencyTokenGenerator {
    
    public init() {}
    
    public func generateToken() -> String {
        return UUID().uuidString
    }
}
