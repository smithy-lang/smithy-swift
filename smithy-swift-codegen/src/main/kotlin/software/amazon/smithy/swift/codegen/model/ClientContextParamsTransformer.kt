package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.aws.reterminus.EndpointRuleset
import software.amazon.smithy.aws.reterminus.lang.parameters.ParameterType
import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.rulesengine.traits.ClientContextParamDefinition
import software.amazon.smithy.rulesengine.traits.ClientContextParamsTrait
import software.amazon.smithy.rulesengine.traits.EndpointRuleSetTrait
import software.amazon.smithy.swift.codegen.getOrNull

/*
 * Transforms the model to add the ClientContextParamsTrait to the service.
 */
class ClientContextParamsTransformer {
    companion object {
        fun transform(model: Model, service: ServiceShape): Model {
            val next = transformInner(model, service)
            if (next == model) {
                throw CodegenException("model $model is equal to $next, loop detected")
            }
            return if (next == null) {
                model
            } else {
                NestedShapeTransformer.transform(next, service)
            }
        }

        /*
         * Transforms the model by adding client context parameters to the service from endpoint rulesets.
         */
        private fun transformInner(model: Model, service: ServiceShape): Model? {
            val transformer = ModelTransformer.create()
            val updated = transformer.mapShapes(model) { shape ->
                when (shape) {
                    is ServiceShape -> {
                        val shapeBuilder = shape.toBuilder()
                        var paramsTrait = ClientContextParamsTrait.builder()

                        paramsTrait.putParameter("Endpoint", ClientContextParamDefinition.builder().type(ShapeType.STRING).build())

                        service.getTrait<EndpointRuleSetTrait>()?.ruleSet?.let { ruleSet ->
                            var endpointRuleSet = EndpointRuleset.fromNode(ruleSet)
                            endpointRuleSet.parameters.toList()
                                .filter {
                                    it.builtIn.isPresent
                                }
                                .map {
                                    val definition = ClientContextParamDefinition.builder()
                                        .type(it.type.toShapeType())
                                        .documentation(it.documentation.getOrNull())
                                    it.name.toString() to definition.build()
                                }
                                .forEach {
                                    paramsTrait.putParameter(it.first, it.second)
                                }
                        }

                        val existing = shape.getTrait<ClientContextParamsTrait>()
                        existing?.parameters?.forEach {
                            paramsTrait.putParameter(it.key, it.value)
                        }
                        shapeBuilder.addTrait(paramsTrait.build())
                        shapeBuilder.build()
                    }
                    else -> shape
                }
            }

            return updated
        }
    }
}

fun ParameterType.toShapeType(): ShapeType? {
    return when (this) {
        ParameterType.STRING -> ShapeType.STRING
        ParameterType.BOOLEAN -> ShapeType.BOOLEAN
        else -> null
    }
}
