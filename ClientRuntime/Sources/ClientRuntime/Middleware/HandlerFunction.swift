 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

public typealias HandlerFunction<TContext, TSubject, TError: Error> = (TContext, Result<TSubject, TError>) -> Result<TSubject, TError>
