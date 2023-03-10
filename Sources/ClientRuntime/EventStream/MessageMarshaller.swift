//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol MessageMarshaller {
    func marshall(encoder: RequestEncoder) throws -> EventStream.Message
}
