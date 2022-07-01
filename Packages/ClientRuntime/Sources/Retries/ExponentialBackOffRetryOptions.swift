//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct ExponentialBackOffRetryOptions {
    public let maxRetries: Int
    public let backOffScaleFactor: UInt32
    public let jitterMode: ExponentialBackOffJitterMode
    public let generateRandom: (() -> UInt64)?
    
    public init(maxRetries: Int = 10,
                backOffScaleFactor: UInt32 = 25,
                jitterMode: ExponentialBackOffJitterMode = .default,
                generateRandom: (() -> UInt64)? = nil) {
        self.maxRetries = maxRetries
        self.backOffScaleFactor = backOffScaleFactor
        self.jitterMode = jitterMode
        self.generateRandom = generateRandom
    }
}

extension ExponentialBackOffRetryOptions {
    func toCRTType() -> CRTExponentialBackoffRetryOptions {
        return CRTExponentialBackoffRetryOptions(eventLoopGroup: SDKDefaultIO.shared.eventLoopGroup,
                                                 maxRetries: maxRetries,
                                                 backOffScaleFactor: backOffScaleFactor,
                                                 jitterMode: jitterMode.toCRTType(),
                                                 generateRandom: generateRandom)
    }
}
