// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public typealias HandlerFunction<MInput,
                                 MOutput,
                                 Context: MiddlewareContext> = (Context,
                                                                MInput) -> Result<MOutput, Error>
