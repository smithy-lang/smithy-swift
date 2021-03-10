package software.amazon.smithy.swift.codegen
import java.util.Optional

fun <T> Optional<T>.getOrNull(): T? = if (isPresent) get() else null