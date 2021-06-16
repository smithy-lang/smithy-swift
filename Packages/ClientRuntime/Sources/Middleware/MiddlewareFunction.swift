// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public typealias MiddlewareFunction<MInput,
                                    MOutput,
                                    Context: MiddlewareContext,
                                    MError: Error> = (Context,
                                                      MInput,
                                                      AnyHandler<MInput,
                                                                 MOutput,
                                                                 Context,
                                                                 MError>) -> Result<MOutput, MError>
