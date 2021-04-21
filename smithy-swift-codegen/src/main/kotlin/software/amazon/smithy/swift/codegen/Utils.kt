package software.amazon.smithy.swift.codegen
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.traits.SensitiveTrait
import software.amazon.smithy.swift.codegen.SwiftSmithyConstants.SENSITIVE_REDACTED
import software.amazon.smithy.swift.codegen.SwiftSmithyConstants.SYMBOL_BODY_POSTFIX
import java.util.Optional

fun <T> Optional<T>.getOrNull(): T? = if (isPresent) get() else null

fun String.removeSurroundingBackticks() = removeSurrounding("`", "`")

fun String.redactIfNecessary(member: MemberShape, model: Model) =
    if (member.getMemberTrait(model, SensitiveTrait::class.java).isPresent) SENSITIVE_REDACTED else this

object SwiftSmithyConstants {
    const val SENSITIVE_REDACTED = "*** Sensitive Data Redacted ***"
    const val SYMBOL_BODY_POSTFIX = "Body"
}

fun Symbol.bodyName() = name + SYMBOL_BODY_POSTFIX
