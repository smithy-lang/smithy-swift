//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct RetryTokenAdapter: Token {
    public let crtToken: CRTAWSRetryToken
    
    public init(crtToken: CRTAWSRetryToken) {
        self.crtToken = crtToken
    }
}
