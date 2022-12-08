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

extension SdkError: CodedError {

    /// The error code associated with this error, or `nil` if the error is not a `CodedError` or
    /// the error's code is unknown.
    public var errorCode: String? {
        switch self {
        case .service(let error, _):
            return (error as? CodedError)?.errorCode
        case .client(let error, _):
            return (error as? CodedError)?.errorCode
        case .unknown(let error):
            return (error as? CodedError)?.errorCode
        }
    }
}
