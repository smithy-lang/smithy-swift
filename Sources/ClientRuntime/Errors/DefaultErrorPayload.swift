/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public struct DefaultErrorPayload: Decodable {
    let message: String?
    let errorType: String?
}