/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public protocol ServiceError {
    var _retryable: Bool { get set }
    var _isThrottling: Bool { get set}
    var _type: ErrorType { get set }
    var _message: String? { get set }

    /// The non-namespaced name of the Smithy shape for this error,
    /// or `nil` if the Smithy type is not known.
    var _smithyErrorTypeName: String? { get }
}

public enum ErrorType: Equatable {
    case server
    case client
    case unknown
}
