//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyHTTPAPI.SDKURLQueryItem

public typealias QueryItemProvider<T> = (T) throws -> [SDKURLQueryItem]
