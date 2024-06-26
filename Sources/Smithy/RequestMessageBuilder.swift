//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Builder for a request message.
public protocol RequestMessageBuilder<RequestType>: AnyObject {

    /// The type of the request message this builder builds.
    associatedtype RequestType: RequestMessage

    init()

    func withHost(_ host: String) -> Self

    func withBody(_ body: ByteStream) -> Self

    /// - Returns: The built request.
    func build() -> RequestType
}
