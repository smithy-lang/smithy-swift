/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public protocol HttpServiceError: ServiceError {
    var _statusCode: HttpStatusCode? { get set }
    var _headers: Headers? { get set }
}
