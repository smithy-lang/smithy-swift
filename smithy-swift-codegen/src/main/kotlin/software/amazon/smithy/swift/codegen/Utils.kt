/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen
import java.util.Optional

fun <T> Optional<T>.getOrNull(): T? = if (isPresent) get() else null

fun String.removeSurroundingBackticks() = removeSurrounding("`", "`")
