//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

public typealias HandlerFunction<MInput,
                                 MOutput,
                                 MError: Error> = (Context, MInput) -> Result<MOutput, MError>
