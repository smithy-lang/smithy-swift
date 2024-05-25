//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol MiddlewareContext: HasAttributes {
    var attributes: Attributes { get set }
}
