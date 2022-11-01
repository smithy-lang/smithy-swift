package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait.Format

class TimestampEncodeGenerator(
    val container: String,
    val property: String,
    val codingKey: String?,
    val format: TimestampFormatTrait.Format
) {
    // Generates and returns the Swift code for encoding a timestamp
    // For example, `try encodeContainer.encodeTimestamp(sampleTime, format: .dateTime, forKey: .sampleTime)`
    fun generate(): String {
        val swiftFormat = TimestampHelpers.generateTimestampFormatEnumValue(this.format)
        var arguments = mutableListOf(
            "${this.property}",
            "format: .$swiftFormat"
        )
        if (this.codingKey != null) {
            arguments.add("forKey: ${this.codingKey}")
        }

        val argumentsAsString = arguments.joinToString(", ")
        return "try ${this.container}.encodeTimestamp($argumentsAsString)"
    }
}

class TimestampDecodeGenerator(
    val container: String,
    val codingKey: String,
    val format: TimestampFormatTrait.Format,
    val optional: Boolean = false
) {
    // Generates and returns the Swift code for encoding a timestamp
    // For example, `try encodeContainer.encodeTimestamp(sampleTime, format: .dateTime, forKey: .sampleTime)`
    fun generate(): String {
        val decodeVerb = if (optional) "decodeTimestampIfPresent" else "decodeTimestamp"
        val swiftFormat = TimestampHelpers.generateTimestampFormatEnumValue(this.format)
        val arguments = listOf(
            ".$swiftFormat",
            "forKey: ${this.codingKey}"
        )
        val argumentsAsString = arguments.joinToString(", ")
        return "try ${this.container}.$decodeVerb($argumentsAsString)"
    }
}
