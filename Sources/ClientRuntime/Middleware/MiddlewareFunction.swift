//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

public typealias MiddlewareFunction<MInput, MOutput> =
    (Context, MInput, AnyHandler<MInput, MOutput>) async throws -> MOutput
