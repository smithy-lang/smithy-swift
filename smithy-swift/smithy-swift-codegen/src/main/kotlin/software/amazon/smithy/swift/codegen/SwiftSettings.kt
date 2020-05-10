package software.amazon.smithy.swift.codegen

import java.util.*
import java.util.logging.Logger
import kotlin.streams.toList
import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.node.StringNode
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId

private const val SERVICE = "service"
private const val MODULE_NAME = "module"
private const val MODULE_DESCRIPTION = "moduleDescription"
private const val MODULE_VERSION = "moduleVersion"
private const val GIT_REPO = "gitRepo"
private const val HOMEPAGE = "homepage"
private const val AUTHOR = "author"

class SwiftSettings(val service: ShapeId,
                    val moduleName: String,
                    val moduleVersion: String,
                    val moduleDescription: String,
                    val author: String,
                    val homepage: String,
                    val gitRepo: String) {

companion object {
    private val LOGGER: Logger = Logger.getLogger(SwiftSettings::class.java.name)
    /**
     * Create settings from a configuration object node.
     *
     * @param model Model to infer the service from (if not explicitly set in config)
     * @param config Config object to load
     * @throws software.amazon.smithy.model.node.ExpectationNotMetException
     * @return Returns the extracted settings
     */
    fun from(model: Model, config: ObjectNode): SwiftSettings {
        config.warnIfAdditionalProperties(arrayListOf(SERVICE, MODULE_NAME, MODULE_DESCRIPTION, MODULE_VERSION, AUTHOR, HOMEPAGE, GIT_REPO))

        val service = config.getStringMember(SERVICE)
            .map(StringNode::expectShapeId)
            .orElseGet { inferService(model) }

        val moduleName = config.expectStringMember(MODULE_NAME).value
        val version = config.expectStringMember(MODULE_VERSION).value
        val desc = config.getStringMemberOrDefault(MODULE_DESCRIPTION, "$moduleName client")
        val homepage = config.expectStringMember(HOMEPAGE).value
        val author = config.expectStringMember(AUTHOR).value
        val gitRepo = config.expectStringMember(GIT_REPO).value
        return SwiftSettings(service, moduleName, version, desc, author, homepage, gitRepo)
    }
    // infer the service to generate from a model
    private fun inferService(model: Model): ShapeId {
        val services = model.shapes(ServiceShape::class.java)
            .map(Shape::getId)
            .sorted()
            .toList()

        when {
            services.isEmpty() -> {
                throw CodegenException(
                    "Cannot infer a service to generate because the model does not " +
                            "contain any service shapes"
                )
            }
            services.size > 1 -> {
                throw CodegenException(
                    "Cannot infer service to generate because the model contains " +
                            "multiple service shapes: " + services
                )
            }
            else -> {
                val service = services[0]
                LOGGER.info("Inferring service to generate as: $service")
                return service
            }
        }
    }
}
    /**
     * Gets the corresponding [ServiceShape] from a model.
     *
     * @param model Model to search for the service shape by ID.
     * @return Returns the found `Service`.
     * @throws NullPointerException if the service has not been set.
     * @throws CodegenException if the service is invalid or not found.
     */
    fun getService(model: Model): ServiceShape {
        return model
            .getShape(this.service)
            .orElseThrow { CodegenException("Service shape not found: " + this.service) }
            .asServiceShape()
            .orElseThrow { CodegenException("Shape is not a Service: " + this.service) }
    }
}
