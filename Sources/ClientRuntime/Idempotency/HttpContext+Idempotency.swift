//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.Attributes
import struct SmithyAPI.AttributeKey
import class SmithyAPI.OperationContext
import class SmithyAPI.OperationContextBuilder
import enum SmithyHTTPAPI.AttributeKeys

extension OperationContext {

    public func getIdempotencyTokenGenerator() -> IdempotencyTokenGenerator {
        return attributes.get(key: idempotencyTokenGeneratorKey)!
    }
}

extension OperationContextBuilder {

    @discardableResult
    public func withIdempotencyTokenGenerator(value: IdempotencyTokenGenerator) -> Self {
        self.attributes.set(key: idempotencyTokenGeneratorKey, value: value)
        return self
    }
}

private let idempotencyTokenGeneratorKey = AttributeKey<IdempotencyTokenGenerator>(name: "IdempotencyTokenGenerator")
