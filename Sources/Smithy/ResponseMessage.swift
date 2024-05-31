//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Message that is sent from service to client.
public protocol ResponseMessage {

    /// The body of the response.
    var body: ByteStream { get }
}
