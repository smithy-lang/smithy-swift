package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.jmespath.JmespathExpression
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.DoubleShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.rulesengine.language.EndpointRuleSet
import software.amazon.smithy.rulesengine.language.syntax.parameters.Parameter
import software.amazon.smithy.rulesengine.language.syntax.parameters.ParameterType
import software.amazon.smithy.rulesengine.traits.ClientContextParamDefinition
import software.amazon.smithy.rulesengine.traits.ClientContextParamsTrait
import software.amazon.smithy.rulesengine.traits.ContextParamTrait
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.rulesengine.traits.OperationContextParamDefinition
import software.amazon.smithy.rulesengine.traits.OperationContextParamsTrait
import software.amazon.smithy.rulesengine.traits.StaticContextParamDefinition
import software.amazon.smithy.rulesengine.traits.StaticContextParamsTrait
import software.amazon.smithy.swift.codegen.AuthSchemeResolverGenerator
import software.amazon.smithy.swift.codegen.SwiftSymbolProvider
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils
import software.amazon.smithy.swift.codegen.middleware.MiddlewareRenderable
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.waiters.JMESPathVisitor
import software.amazon.smithy.swift.codegen.waiters.JMESVariable

/**
 * Generates EndpointResolverMiddleware interception code.
 * Including creation of EndpointParams instance and pass it as middleware param along with EndpointResolver
 */
open class OperationEndpointResolverMiddleware(
    val ctx: ProtocolGenerator.GenerationContext,
    val endpointResolverMiddlewareSymbol: Symbol,
) : MiddlewareRenderable {
    override val name = "EndpointResolverMiddleware"

    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
    ) {
        renderEndpointParams(ctx, writer, op)

        // Write code that saves endpoint params to middleware context for use in auth scheme middleware when using rules-based auth scheme resolvers
        if (AuthSchemeResolverGenerator.usesRulesBasedAuthResolver(ctx)) {
            writer.write(
                "context.set(key: \$N<EndpointParams>(name: \$S), value: endpointParamsBlock(context))",
                SmithyTypes.AttributeKey,
                "EndpointParams",
            )
        }

        super.renderSpecific(ctx, writer, op, operationStackName, "applyEndpoint")
    }

    override fun renderMiddlewareInit(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
    ) {
        val output = MiddlewareShapeUtils.outputSymbol(ctx.symbolProvider, ctx.model, op)
        writer.write(
            "\$N<\$N, EndpointParams>(paramsBlock: endpointParamsBlock, resolverBlock: { [config] in try config.endpointResolver.resolve(params: \$\$0) })",
            endpointResolverMiddlewareSymbol,
            output,
        )
    }

    private fun renderEndpointParams(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
    ) {
        val params = mutableListOf<String>()
        ctx.service.getTrait<EndpointRuleSetTrait>()?.ruleSet?.let { node ->
            val ruleSet = EndpointRuleSet.fromNode(node)
            val staticContextParams = op.getTrait<StaticContextParamsTrait>()?.parameters ?: emptyMap()
            val operationContextParams = op.getTrait<OperationContextParamsTrait>()?.parameters ?: emptyMap()
            val clientContextParams = ctx.service.getTrait<ClientContextParamsTrait>()?.parameters ?: emptyMap()
            val parameters = ruleSet.parameters.toList()
            val setToUseForUniqueVarNamesInOperationContextParamCodegen = mutableSetOf<String>()
            parameters
                .toList()
                .sortedBy { it.name.toString() }
                .forEach { param ->
                    val memberName = param.name.toString().toLowerCamelCase()
                    val contextParam =
                        ctx.model
                            .expectShape(op.inputShape)
                            .members()
                            .firstOrNull { it.getTrait<ContextParamTrait>()?.name == param.name.toString() }
                    val value =
                        resolveParameterValue(
                            op,
                            param,
                            staticContextParams[param.name.toString()],
                            contextParam,
                            setToUseForUniqueVarNamesInOperationContextParamCodegen,
                            operationContextParams[param.name.toString()],
                            clientContextParams[param.name.toString()],
                            writer,
                        )
                    value?.let {
                        params.add("$memberName: $it")
                    }
                }
        }
        writer.openBlock(
            "let endpointParamsBlock = { [config] (context: \$N) in",
            "}",
            SmithyTypes.Context,
        ) {
            writer.write("EndpointParams(\$L)", params.joinToString(", "))
        }
    }

    /**
     * Resolve the parameter value based on the following order
     * 1. staticContextParams: direct value from the static context params
     * 2. contextParam: value from a top level input member of the input shape
     * 3. operationContextParams: any value or string array of values from the member(s) in the input shape
     * 4. clientContextParams: value from the client config
     * 5. Built-In Bindings: value from the client config
     * 6. Built-in binding default values: default value from the built-in binding
     */
    private fun resolveParameterValue(
        op: OperationShape,
        param: Parameter,
        staticContextParam: StaticContextParamDefinition?,
        contextParam: MemberShape?,
        tempVarSet: MutableSet<String>,
        operationContextParam: OperationContextParamDefinition?,
        clientContextParam: ClientContextParamDefinition?,
        writer: SwiftWriter,
    ): String? =
        when {
            staticContextParam != null -> {
                swiftParam(param.type, staticContextParam.value)
            }
            contextParam != null -> {
                "input.${contextParam.memberName.toLowerCamelCase()}"
            }
            operationContextParam != null -> {
                // Use smithy to parse the text JMESPath expression into a syntax tree to be visited.
                val jmesExpression = JmespathExpression.parse(operationContextParam.path)

                // Set the starting JMES variable (root) to input shape.
                val startingVar = JMESVariable("input", false, ctx.model.expectShape(op.inputShape))

                // Create a model & symbol provider with the JMESPath synthetic types included in it
                val model =
                    ctx.model
                        .toBuilder()
                        .addShapes(listOf(boolShape, stringShape, doubleShape))
                        .build()
                val symbolProvider = SwiftSymbolProvider(model, ctx.settings)

                // Create a visitor & send it through the AST.  actual will hold the name of the variable
                // with the result of the expression.
                val visitor = JMESPathVisitor(writer, startingVar, model, symbolProvider, tempVarSet)
                writer.write("// OperationContextParam - JMESPath expression: \"${operationContextParam.path}\"")
                val actual = jmesExpression.accept(visitor)

                // Add names of used temp vars
                tempVarSet.addAll(visitor.tempVars)

                // The name of the variable that holds the final evaluated value of the JMESPath string.
                val name = actual.name
                // Handle default logic
                when {
                    param.default.isPresent -> {
                        "$name ?? ${param.defaultValueLiteral}"
                    } else -> {
                        name
                    }
                }
            }
            clientContextParam != null -> {
                handleClientContextParam(param, writer)
            }
            param.isBuiltIn -> {
                handleBuiltInParam(param, writer)
            }
            else -> {
                // we can't resolve this param, skip it
                null
            }
        }

    open fun handleClientContextParam(
        param: Parameter,
        writer: SwiftWriter,
    ): String {
        // if a default is present, use `?? default`, otherwise just return `config.myParam`
        return if (param.default.isPresent) {
            "config.${param.name.toString().toLowerCamelCase()} ?? ${param.defaultValueLiteral}"
        } else {
            "config.${param.name.toString().toLowerCamelCase()}"
        }
    }

    open fun handleBuiltInParam(
        param: Parameter,
        writer: SwiftWriter,
    ): String {
        // default behavior for handling endpoint if not overriden
        if (getBuiltInName(param) == "endpoint") {
            return "config.endpoint"
        }

        // required but no default
        return if (param.isRequired && !param.default.isPresent) {
            // case: required but no default => guard / unwrap
            writer.openBlock("guard let ${getBuiltInName(param)} = config.${getBuiltInName(param)} else {", "}") {
                writer.write(
                    "throw \$N.unknownError(\"Missing required parameter: \$L\")",
                    SmithyTypes.ClientError,
                    param.name.toString(),
                )
            }
            param.name.toString().toLowerCamelCase()
        } else if (param.default.isPresent) {
            // has a default => use ?? default
            "config.${getBuiltInName(param)} ?? ${param.defaultValueLiteral}"
        } else {
            // not required, no default => just use config
            "config.${getBuiltInName(param)}"
        }
    }

    fun getBuiltInName(param: Parameter): String =
        param.builtIn
            .get()
            .split("::")
            .last()
            .toLowerCamelCase()

    // Shapes used within JMESPath expressions
    private val stringShape = StringShape.builder().id("smithy.swift.synthetic#LiteralString").build()
    private val boolShape = BooleanShape.builder().id("smithy.swift.synthetic#LiteralBoolean").build()
    private val doubleShape = DoubleShape.builder().id("smithy.swift.synthetic#LiteralDouble").build()
}

val Parameter.defaultValueLiteral: String
    get() = swiftParam(type, default.get().toNode())

private fun swiftParam(
    parameterType: ParameterType,
    node: Node,
): String =
    when (parameterType) {
        ParameterType.STRING -> "\"${node}\""
        ParameterType.BOOLEAN -> node.toString()
        ParameterType.STRING_ARRAY -> "[${node.expectArrayNode().map { "\"$it\"" }.joinToString(", ")}]"
    }
