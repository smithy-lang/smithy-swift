package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * HttpFeature interface that allows middleware customizations to be registered and configured
 * with the protocol generator
 */
interface HttpFeature {
    // the name of the feature to install
    val name: String

    // flag that controls whether renderConfigure() needs called
    val needsConfigure: Boolean
        get() = true

    /**
     * Instantiate the feature
     *
     * Example
     * ```
     * let encoder: JSONEncoder = JSONEncoder()
     * ```
     */
    fun renderInstantiation(writer: SwiftWriter) {}

    /**
     * Render the configuration needed post instantiation of a feature
     *
     * Example
     * ```
     * encoder.outputFormatting = .sortedKeys
     * encoder.dateEncodingStrategy = .iso8601
     * encoder.dataEncodingStrategy = .base64
     * encoder.keyEncodingStrategy = .convertToSnakeCase
     * ```
     */
    fun renderConfiguration(writer: SwiftWriter) {}

    /**
     * Render the initialization of a feature inside the class
     *
     * Example
     * ```
     * self.encoder = config.encoder ?? encoder
     * self.decoder = config.decoder ?? decoder
     * ```
     */
    fun renderInitialization(writer: SwiftWriter, nameOfConfigObject: String) {}

    /**
     * Register any imports or dependencies that will be needed to use this feature at runtime
     */
    fun addImportsAndDependencies(writer: SwiftWriter) {}
}

/**
 * `HttpRequestEncoder` feature to help instantiate RequestEncoder
 * @property requestEncoderName The name of the request encoder (e.g. JSONEncoder)
 * @property requestEncoderOptions Map of options to set on the request encoder instance
 */
abstract class HttpRequestEncoder(private val requestEncoderName: String, private val requestEncoderOptions: MutableMap<String, String> = mutableMapOf()) : HttpFeature {
    override val name: String = "encoder"
    override fun renderInstantiation(writer: SwiftWriter) {
        writer.write("let \$L = $requestEncoderName()", name)
    }

    override fun renderConfiguration(writer: SwiftWriter) {
        requestEncoderOptions.forEach {
                requestEncoderOptionName, requestEncoderOptionValue ->
            writer.write("encoder.$requestEncoderOptionName = $requestEncoderOptionValue")
        }
    }

    override fun renderInitialization(writer: SwiftWriter, nameOfConfigObject: String) {
        writer.write("self.encoder = \$L.encoder ?? \$L", nameOfConfigObject, name)
    }
}

/**
 * `HttpRequestDecoder` feature to help instantiate RequestDecoder
 * @property requestDecoderName The name of the request decoder (e.g. JSONDecoder)
 * @property requestDecoderOptions Map of options to set on the request decoder instance
 */
abstract class HttpResponseDecoder(private val requestDecoderName: String, private val requestDecoderOptions: MutableMap<String, String> = mutableMapOf()) : HttpFeature {
    override val name: String = "decoder"
    override fun renderInstantiation(writer: SwiftWriter) {
        writer.write("let \$L = $requestDecoderName()", name)
    }

    override fun renderConfiguration(writer: SwiftWriter) {
        requestDecoderOptions.forEach {
                requestDecoderOptionName, requestDecoderOptionValue ->
            writer.write("decoder.$requestDecoderOptionName = $requestDecoderOptionValue")
        }
    }

    override fun renderInitialization(writer: SwiftWriter, nameOfConfigObject: String) {
        writer.write("self.decoder = \$L.decoder ?? \$L", nameOfConfigObject, name)
    }
}

class DefaultRequestEncoder(private val requestEncoderOptions: MutableMap<String, String> = mutableMapOf()) : HttpRequestEncoder("encoder", requestEncoderOptions) {
    override fun renderInstantiation(writer: SwiftWriter) {
        // render nothing as we are relying on an encoder passed via the config object
    }
    override fun renderInitialization(writer: SwiftWriter, nameOfConfigObject: String) {
        writer.write("self.encoder = \$L.encoder", nameOfConfigObject)
    }
}
class DefaultResponseDecoder(private val responseDecoderOptions: MutableMap<String, String> = mutableMapOf()) : HttpResponseDecoder("decoder", responseDecoderOptions) {
    override fun renderInstantiation(writer: SwiftWriter) {
        // render nothing as we are relying on an encoder passed via the config object
    }
    override fun renderInitialization(writer: SwiftWriter, nameOfConfigObject: String) {
        writer.write("self.decoder = \$L.decoder", nameOfConfigObject)
    }
}
