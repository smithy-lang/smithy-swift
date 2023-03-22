//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Stream adapter that decodes input data into `EventStream.Message` objects.
public protocol MessageDecoderStream: AsyncSequence where Event == Element {
    associatedtype Event
}

extension MessageDecoderStream {
    /// Returns an `AsyncThrowingStream` that decodes input data into `Event` objects.
    public func toAsyncStream() -> AsyncThrowingStream<Event, Error> {
        let stream = AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await event in self {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        return stream
    }
}
