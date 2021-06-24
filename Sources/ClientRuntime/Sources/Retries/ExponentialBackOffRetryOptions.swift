//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct ExponentialBackOffRetryOptions {
    let client: HttpClientEngine
    let maxRetries: Int
    let backOffScaleFactor: UInt32
    let jitterMode: ExponentialBackOffJitterMode
    let generateRandom: (() -> UInt64)?
    
    public init(client: HttpClientEngine,
                maxRetries: Int = 10,
                backOffScaleFactor: UInt32 = 25,
                jitterMode: ExponentialBackOffJitterMode = .default,
                generateRandom: (() -> UInt64)? = nil) {
        self.client = client
        self.maxRetries = maxRetries
        self.backOffScaleFactor = backOffScaleFactor
        self.jitterMode = jitterMode
        self.generateRandom = generateRandom
    }
}

extension ExponentialBackOffRetryOptions {
    func toCRTType() -> CRTExponentialBackoffRetryOptions {
        return CRTExponentialBackoffRetryOptions(eventLoopGroup: client.eventLoopGroup,
                                                 maxRetries: maxRetries,
                                                 backOffScaleFactor: backOffScaleFactor,
                                                 jitterMode: jitterMode.toCRTType(),
                                                 generateRandom: generateRandom)
    }
}
