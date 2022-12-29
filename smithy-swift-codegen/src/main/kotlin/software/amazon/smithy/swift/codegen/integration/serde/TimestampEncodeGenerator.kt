package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait.Format
import software.amazon.smithy.swift.codegen.SwiftWriter

class TimestampEncodeGenerator(
    val container: String,
    val property: String,
    val codingKey: String?,
    val format: TimestampFormatTrait.Format
) {
    // Generates and returns the Swift code for encoding a timestamp
    // For example, `try encodeContainer.encodeTimestamp(sampleTime, format: .dateTime, forKey: .sampleTime)`
    fun generate(writer: SwiftWriter) {
        val swiftFormat = TimestampHelpers.generateTimestampFormatEnumValue(this.format)
        writer.writeInline("try \$L.encodeTimestamp(\$L, format: .\$L", this.container, this.property, swiftFormat)
        if (this.codingKey != null) {
            writer.writeInline(", forKey: \$L", this.codingKey)
        }
        writer.writeInline(")")
        writer.ensureNewline()
    }
}

class TimestampDecodeGenerator(
    val memberName: String,
    val container: String,
    val codingKey: String,
    val format: TimestampFormatTrait.Format,
    val optional: Boolean = false
) {
    // Generates and returns the Swift code for encoding a timestamp
    // For example, `try encodeContainer.encodeTimestamp(sampleTime, format: .dateTime, forKey: .sampleTime)`
    fun generate(writer: SwiftWriter) {
        val decodeVerb = if (optional) "decodeTimestampIfPresent" else "decodeTimestamp"
        val swiftFormat = TimestampHelpers.generateTimestampFormatEnumValue(this.format)
        writer.write(
            "let \$L = try \$L.\$L(.\$L, forKey: \$L)",
            this.memberName, this.container, decodeVerb, swiftFormat, this.codingKey
        )
    }
}
