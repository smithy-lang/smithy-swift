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

    // TODO: Is this the right way to do it in swift? Alternatives would be
    //  to have a `Default` protocol which required a static function to
    //  initialize a default instance, or to make `RequestMessage` have a
    //  static `builder` method to do the same.
    init()

    /// - Returns: The built request.
    func build() -> RequestType
}
