//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// protocol for all Inputs that can be paginated.
/// Adds an initializer that does a copy but inserts a new integer based pagination token
public protocol PaginateToken {
    associatedtype Token
    func usingPaginationToken(_ token: Token) -> Self
}
