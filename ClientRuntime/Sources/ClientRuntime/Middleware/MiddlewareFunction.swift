// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public typealias MiddlewareFunction<MInput, MOutput, Context: MiddlewareContext> = (Context, MInput, AnyHandler<MInput, MOutput, Context>) -> Result<MOutput, Error>
