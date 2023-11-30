//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct PaginatorSequence<Input: PaginateToken, OperationStackOutput>: AsyncSequence 
    where Input.Token: Equatable {
    
    public typealias Element = OperationStackOutput
    let input: Input
    let inputKey: KeyPath<Input, Input.Token?>?
    let outputKey: KeyPath<OperationStackOutput, Input.Token?>
    let paginationFunction: (Input) async throws -> OperationStackOutput

    public init(input: Input,
                inputKey: KeyPath<Input, Input.Token?>? = nil,
                outputKey: KeyPath<OperationStackOutput, Input.Token?>,
                paginationFunction: @escaping (Input) async throws -> OperationStackOutput) {
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
        public mutating func next() async throws -> OperationStackOutput? {
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
