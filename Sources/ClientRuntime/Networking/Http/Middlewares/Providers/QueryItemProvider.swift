//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.URIQueryItem

public typealias QueryItemProvider<T> = (T) throws -> [URIQueryItem]
