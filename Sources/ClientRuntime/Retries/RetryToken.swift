//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct RetryToken {
    public let crtToken: AwsCommonRuntimeKit.RetryToken
    
    public init(crtToken: AwsCommonRuntimeKit.RetryToken) {
        self.crtToken = crtToken
    }
}
