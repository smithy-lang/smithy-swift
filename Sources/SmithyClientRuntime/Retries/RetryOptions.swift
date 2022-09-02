//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct RetryOptions {
    public let initialBucketCapacity: Int
    
    public let backOffRetryOptions: ExponentialBackOffRetryOptions
    
    public init(initialBucketCapacity: Int = 500,
                backOffRetryOptions: ExponentialBackOffRetryOptions) {
        self.initialBucketCapacity = initialBucketCapacity
        self.backOffRetryOptions = backOffRetryOptions
    }
}

public extension RetryOptions {
    func toCRTType() -> TransformRetryOptions {
        return TransformRetryOptions(initialBucketCapacity: initialBucketCapacity,
                            backOffRetryOptions: backOffRetryOptions.toCRTType())
    }
}

public struct TransformRetryOptions: CRTRetryOptions {
    public var initialBucketCapacity: Int
    public var backOffRetryOptions: CRTExponentialBackoffRetryOptions
    
    init(initialBucketCapacity: Int, backOffRetryOptions: CRTExponentialBackoffRetryOptions) {
        self.initialBucketCapacity = initialBucketCapacity
        self.backOffRetryOptions = backOffRetryOptions
    }
}
