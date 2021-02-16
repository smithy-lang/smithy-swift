package software.amazon.smithy.swift.codegen

class IdempotencyTokenMiddlewareGenerator(
    private val writer: SwiftWriter,
    private val idempotentMemberName: String,
    private val operationMiddlewareStackName: String,
    private val outputShapeName: String,
    private val outputErrorShapeName: String
) {
    /**
     * If given the following smithy in the input of an operation:
     * ```
     * structure IdempotentTokenStruct {
     * @idempotencyToken
     * token: String
     * }
     *
     * ```
     * The operation would generate the following inside its implementation to provide a default token from the given generator
     * before the request is made
     * ```
     * operationStack.initializeStep.intercept(position: .before, id: "IdempotencyTokenMiddleware") { (context, input, next) -> Result<OperationOutput<IdempotencyTokenOutput, IdempotencyTokenError>, Error> in
     *    let idempotencyTokenGenerator = context.getIdempotencyTokenGenerator()
     *    var copiedInput = input
     *    if input.token == nil {
     *        copiedInput.token = idempotencyTokenGenerator.generateToken()
     *    }
     *    return next.handle(context: context, input: copiedInput)
     * }
     * ```
     * */
    fun renderIdempotencyMiddleware() {
        // TODO: Need to write a unit test for this
        writer.openBlock("$operationMiddlewareStackName.initializeStep.intercept(position: .before, id: \"IdempotencyTokenMiddleware\") { (context, input, next) -> Result<OperationOutput<$outputShapeName, $outputErrorShapeName>, Error> in", "}") {
            writer.write("let idempotencyTokenGenerator = context.getIdempotencyTokenGenerator()")
            writer.write("var copiedInput = input")
            writer.openBlock("if input.$idempotentMemberName == nil {", "}") {
                writer.write("copiedInput.$idempotentMemberName = idempotencyTokenGenerator.generateToken()")
            }
            writer.write("return next.handle(context: context, input: copiedInput)")
        }
    }
}
