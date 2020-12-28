// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public typealias MiddlewareFunction<MInput, MOutput> = (MiddlewareContext, MInput, AnyHandler<MInput, MOutput>) -> Result<MOutput, Error>
