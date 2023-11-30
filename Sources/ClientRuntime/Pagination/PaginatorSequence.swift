//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct PaginatorSequence<OperationStackInput: PaginateToken, OperationStackOutput>: AsyncSequence
    where OperationStackInput.Token: Equatable {

    public typealias Element = OperationStackOutput
    let input: OperationStackInput
    let inputKey: KeyPath<OperationStackInput, OperationStackInput.Token?>?
    let outputKey: KeyPath<OperationStackOutput, OperationStackInput.Token?>
    let paginationFunction: (OperationStackInput) async throws -> OperationStackOutput

    public init(input: OperationStackInput,
                inputKey: KeyPath<OperationStackInput, OperationStackInput.Token?>? = nil,
                outputKey: KeyPath<OperationStackOutput, OperationStackInput.Token?>,
                paginationFunction: @escaping (OperationStackInput) async throws -> OperationStackOutput) {
        self.input = input
        self.inputKey = inputKey
        self.outputKey = outputKey
        self.paginationFunction = paginationFunction
    }

    public struct PaginationIterator: AsyncIteratorProtocol {
        var input: OperationStackInput
        let sequence: PaginatorSequence
        var token: OperationStackInput.Token?
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
