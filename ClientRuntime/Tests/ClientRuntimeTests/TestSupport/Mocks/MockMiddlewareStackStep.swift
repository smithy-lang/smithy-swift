//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import ClientRuntime

public class MockMiddlewareStackStep<OperationStackInput, OperationStackOutput>: MiddlewareStackStep<OperationStackInput, OperationStackOutput> {

    let callback: MockMiddlewareStackStepCallbackType?

    typealias MockMiddlewareStackStepCallbackType = (Context, MInput) -> Result<MOutput, Error>

    init(stack: AnyMiddlewareStack<OperationStackInput, OperationStackOutput, Context>,
                handler: AnyHandler<OperationStackInput, OperationStackOutput, Context>? = nil,
                callback: MockMiddlewareStackStepCallbackType? = nil) {
        self.callback = callback

        super.init(stack:stack, handler:handler)
    }

    public override func handle<H>(context: Context, input: MInput, next: H) -> Result<MOutput, Error> where H: Handler,
                                                                                             MInput == H.Input,
                                                                                             MOutput == H.Output,
                                                                                             Context == H.Context {
        if let callback = callback {
            let _ = callback(context, input)
        }
        return super.handle(context: context, input: input, next: next)
    }

}
