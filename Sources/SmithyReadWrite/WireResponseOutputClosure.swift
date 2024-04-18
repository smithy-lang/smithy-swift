//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias WireResponseOutputClosure<WireResponse, OperationStackOutput> =
    (WireResponse) async throws -> OperationStackOutput
