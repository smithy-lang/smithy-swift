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

    /// Returns the error code.  The error code, if available, is decoded
    /// from the API response, and generally indicates the type/nature
    /// of the AWS server error.
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
