//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension EventStream {
    public struct AsyncOutputStream<Element>: AsyncSequence {
        public typealias Element = Element

        internal let stream: AsyncThrowingStream<Element, Error>

        public init(_ stream: AsyncThrowingStream<Element, Error>) {
            self.stream = stream
        }

        public func makeAsyncIterator() -> Iterator {
            return AsyncIterator(iterator: stream.makeAsyncIterator())
        }

        public struct Iterator: AsyncIteratorProtocol {
            var iterator: AsyncThrowingStream<Element, Error>.Iterator

            init(iterator: AsyncThrowingStream<Element, Error>.Iterator) {
                self.iterator = iterator
            }

            mutating public func next() async throws -> Element? {
                return try await iterator.next()
            }
        }
    }
}

extension EventStream.AsyncOutputStream: Equatable {
    public static func == (lhs: EventStream.AsyncOutputStream<Element>, rhs: EventStream.AsyncOutputStream<Element>) -> Bool {
        false
    }
}
