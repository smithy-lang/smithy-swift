//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Message that is sent from client to service.
public protocol RequestMessage {

    /// The type of the builder that can build this request message.
    associatedtype RequestBuilderType: RequestMessageBuilder<Self>

    /// The host the request will be sent to.
    var host: String { get }

    /// The body of the request.
    var body: ByteStream { get }

    // The uri of the request
    var destination: URI { get }

    /// - Returns: A new builder for this request message, with all properties copied.
    func toBuilder() -> RequestBuilderType
}
