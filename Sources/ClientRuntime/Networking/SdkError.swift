/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public enum SdkError<E>: Error {
  // Service specific error
  case service(E, HttpResponse)

  // error from the underlying client runtime
  case client(ClientError, HttpResponse? = nil)

  // unknown error
  case unknown(Error?)

}

extension SdkError: WaiterTypedError {

    /// The Smithy identifier, without namespace, for the type of this error, or `nil` if the
    /// error has no known type.
    public var waiterErrorType: String? {
        switch self {
        case .service(let error, _):
            return (error as? WaiterTypedError)?.waiterErrorType
        case .client(let error, _):
            return error.waiterErrorType
        case .unknown(let error):
            return (error as? WaiterTypedError)?.waiterErrorType
        }
    }
}
