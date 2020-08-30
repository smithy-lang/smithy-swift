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
    override val name: String = "HttpRequestEncoder"
    override fun renderInstantiation(writer: SwiftWriter) {
        writer.write("let encoder = $requestEncoderName()")
    }

    override fun renderConfiguration(writer: SwiftWriter) {
        requestEncoderOptions.forEach {
                requestEncoderOptionName, requestEncoderOptionValue ->
            writer.write("encoder.$requestEncoderOptionName = $requestEncoderOptionValue")
        }
    }
}

/**
 * `HttpRequestDecoder` feature to help instantiate RequestDecoder
 * @property requestDecoderName The name of the request decoder (e.g. JSONDecoder)
 * @property requestDecoderOptions Map of options to set on the request decoder instance
 */
abstract class HttpResponseDecoder(private val requestDecoderName: String, private val requestDecoderOptions: MutableMap<String, String> = mutableMapOf()) : HttpFeature {
    override val name: String = "HttpRequestDecoder"
    override fun renderInstantiation(writer: SwiftWriter) {
        writer.write("let decoder = $requestDecoderName()")
    }

    override fun renderConfiguration(writer: SwiftWriter) {
        requestDecoderOptions.forEach {
                requestDecoderOptionName, requestDecoderOptionValue ->
            writer.write("decoder.$requestDecoderOptionName = $requestDecoderOptionValue")
        }
    }
}