//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ByteStream

protocol HTTPURLResponse {
    var headers: Headers { get set }
    var body: ByteStream { get set }
    var statusCode: HTTPStatusCode { get set }
    var reason: String? { get set }
}
