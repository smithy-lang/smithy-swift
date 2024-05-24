//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyStreamsAPI
import SmithyEventStreamsAPI
import struct Foundation.Data

/// Stream adapter that encodes input into `Data` objects that are encoded, signed events.
public protocol MessageEncoderStream: Stream, AsyncSequence where Element == Data {
    associatedtype Event

    init(
        stream: AsyncThrowingStream<Event, Error>,
        messageEncoder: MessageEncoder,
        marshalClosure: @escaping MarshalClosure<Event>,
        messageSigner: MessageSigner,
        initialRequestMessage: Message?
    )
}
