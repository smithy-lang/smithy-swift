/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public protocol ServiceError {
    var _retryable: Bool? { get set }
    var _type: ErrorType { get set }
    var _message: String? { get set }
}

public enum ErrorType {
    case server
    case client
    case unknown
}
