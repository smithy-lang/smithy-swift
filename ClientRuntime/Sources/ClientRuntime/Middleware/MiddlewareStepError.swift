// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

enum MiddlewareStepError: Error {
    ///if for some reason in our casting of one step to the next it fails return this with
    ///a string about exactly where the failure occurred
    case castingError(String)
}
