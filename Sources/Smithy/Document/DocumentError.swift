//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum DocumentError: Error {
    case invalidJSONData
    case typeMismatch(String)
    case numberOverflow(String)
    case invalidBase64(String)
    case invalidDateFormat(String)
}
