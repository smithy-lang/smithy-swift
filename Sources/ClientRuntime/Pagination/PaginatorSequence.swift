//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct PaginatorSequence<Input: PaginateToken, Output>: AsyncSequence where Input.Token: Equatable {
    public typealias Element = Output
    let input: Input
    let inputKey: KeyPath<Input, Input.Token?>?
    let outputKey: KeyPath<Output, Input.Token?>
    let paginationFunction: (Input) async throws -> Output

    public init(input: Input,
                inputKey: KeyPath<Input, Input.Token?>? = nil,
                outputKey: KeyPath<Output, Input.Token?>,
                paginationFunction: @escaping (Input) async throws -> Output) {
        self.input = input
        self.inputKey = inputKey
        self.outputKey = outputKey
        self.paginationFunction = paginationFunction
    }

    public struct PaginationIterator: AsyncIteratorProtocol {
        var input: Input
        let sequence: PaginatorSequence
        var token: Input.Token?
        var isFirstPage: Bool = true

        // swiftlint:disable force_cast
        public mutating func next() async throws -> Output? {
            while token != nil || isFirstPage {

                if let token = token,
                   (token is String && !(token as! String).isEmpty) ||
                    (token is [String: Any] && !(token as! [String: Any]).isEmpty) {
                    self.input = input.usingPaginationToken(token)
                }
                let output = try await sequence.paginationFunction(input)
                isFirstPage = false
                token = output[keyPath: sequence.outputKey]
                if token != nil && token == input[keyPath: sequence.inputKey!] {
                    break
                }
                return output
            }
            return nil
        }
        // swiftlint:enable force_cast
    }

    public func makeAsyncIterator() -> PaginationIterator {
        PaginationIterator(input: input, sequence: self)
    }
}
