//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import Foundation

public struct RetryOptions {
    public let initialBucketCapacity: Int
    public let maxRetries: Int
    public let backOffScaleFactor: TimeInterval
    public let jitterMode: ExponentialBackOffJitterMode
    public let generateRandom: (() -> UInt64)?
    
    public init(
        initialBucketCapacity: Int = 500,
        maxRetries: Int = 10,
        backOffScaleFactor: TimeInterval = 0.025,
        jitterMode: ExponentialBackOffJitterMode = .default,
        generateRandom: (() -> UInt64)? = nil
    ) {
        self.initialBucketCapacity = initialBucketCapacity
        self.maxRetries = maxRetries
        self.backOffScaleFactor = backOffScaleFactor
        self.jitterMode = jitterMode
        self.generateRandom = generateRandom
    }
}
