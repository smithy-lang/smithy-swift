//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Stream adapter that decodes input data into `Message` objects.
public protocol MessageDecoderStream: AsyncSequence where Event == Element {
    associatedtype Event: Sendable
}

extension MessageDecoderStream where Self: Sendable {
    /// Returns an `AsyncThrowingStream` that decodes input data into `Event` objects.
    public func toAsyncStream() -> AsyncThrowingStream<Event, Error> where Event == Element {
        let stream = AsyncThrowingStream<Event, Error> { continuation in
            Task { [self] in // explicitly capture self
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
