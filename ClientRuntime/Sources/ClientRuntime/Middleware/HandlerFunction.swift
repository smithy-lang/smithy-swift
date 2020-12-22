// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public typealias HandlerFunction<MInput, MOutput> = (MiddlewareContext, Result<MInput, Error>) -> Result<MOutput, Error>
