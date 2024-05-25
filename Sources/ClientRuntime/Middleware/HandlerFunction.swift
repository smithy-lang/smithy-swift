// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import protocol SmithyAPI.MiddlewareContext

public typealias HandlerFunction<MInput,
                                 MOutput,
                                 Context: MiddlewareContext,
                                 MError: Error> = (Context, MInput) -> Result<MOutput, MError>
