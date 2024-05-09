//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum RetryError: Error {
    case maxAttemptsReached
    case insufficientQuota
}
