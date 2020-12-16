/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public enum SdkError<E>: Error {
  // Service specific error
  case service(E)

  // error from the underlying client runtime
  case client(ClientError)

  // unknown error 
  case unknown(Error?)

}
