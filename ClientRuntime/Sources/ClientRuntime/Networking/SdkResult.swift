/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public typealias SdkResult<R, E> = Result<R, SdkError<E>>

public typealias NetworkResult = (Result<HttpResponse,Error>) -> Void
