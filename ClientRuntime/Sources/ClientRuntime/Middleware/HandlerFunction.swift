// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public typealias HandlerFunction<TSubject, TError: Error> = (MiddlewareContext, Result<TSubject, TError>) -> Result<TSubject, TError>
