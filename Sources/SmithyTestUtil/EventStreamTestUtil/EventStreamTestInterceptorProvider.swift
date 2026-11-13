//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol ClientRuntime.HttpInterceptorProvider
import protocol ClientRuntime.Interceptor
import protocol ClientRuntime.MutableInput
@_spi(SmithyEventStreams) import struct SmithyEventStreams.DefaultMessageEncoder
import SmithyEventStreamsAPI
import SmithyEventStreamsAuthAPI
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

/// Provides an interceptor that configures an event stream message encoder & signer on the operation context,
/// if the SDK has not already configured them.
///
/// Event stream protocol tests verify the serialization of event stream messages.  SDKs that sign event stream
/// messages configure their own encoder & signer, which are left in place; signed messages are unwrapped by
/// ``EventStreamTestUtil/messages(from:)`` before they are verified.
public struct EventStreamTestInterceptorProvider: HttpInterceptorProvider, Sendable {

    public init() {}

    public func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
        EventStreamTestInterceptor<InputType, OutputType>()
    }
}

struct EventStreamTestInterceptor<InputType, OutputType>: Interceptor {
    typealias RequestType = HTTPRequest
    typealias ResponseType = HTTPResponse

    func modifyBeforeSerialization(context: some MutableInput<InputType>) async throws {
        let attributes = context.getAttributes()
        if attributes.messageEncoder == nil {
            attributes.messageEncoder = DefaultMessageEncoder()
        }
        if attributes.messageSigner == nil {
            attributes.messageSigner = UnsignedMessageSigner()
        }
    }
}

/// A message signer that leaves messages unsigned.
struct UnsignedMessageSigner: MessageSigner {

    func sign(message: Message) async throws -> Message {
        message
    }

    func signEmpty() async throws -> Message {
        Message()
    }
}
