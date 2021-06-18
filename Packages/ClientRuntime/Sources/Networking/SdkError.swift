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
