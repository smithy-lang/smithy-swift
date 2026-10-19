/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.endpoints

import software.amazon.smithy.codegen.core.CodegenException
import java.nio.file.Files

/**
 * Runs bdd-bytecoder.py (from aws-c-sdkutils) to compile the JSON form of a
 * smithy.rules#endpointBdd trait into the binary bytecode consumed by the CRT BDD engine.
 */
object BddBytecoder {
    /**
     * @param bytecoderPath path to bdd-bytecoder.py
     * @param traitJson the endpointBdd trait serialized as JSON
     * @param serviceName used only to label temp files and error messages
     * @return the compiled bytecode
     */
    fun compile(
        bytecoderPath: String,
        traitJson: String,
        serviceName: String,
    ): ByteArray {
        val prefix = "bdd-" + serviceName.replace(Regex("[^a-zA-Z0-9._-]"), "_") + "-"
        val input = Files.createTempFile(prefix, ".json")
        val output = Files.createTempFile(prefix, ".bin")
        try {
            Files.writeString(input, traitJson)
            val process =
                ProcessBuilder("python3", bytecoderPath, input.toString(), output.toString())
                    .redirectErrorStream(true)
                    .start()
            val consoleOutput = process.inputStream.bufferedReader().readText()
            val exitCode = process.waitFor()
            if (exitCode != 0) {
                throw CodegenException("bdd-bytecoder.py failed for '$serviceName' (exit $exitCode):\n$consoleOutput")
            }
            val bytecode = Files.readAllBytes(output)
            if (bytecode.isEmpty()) {
                throw CodegenException("bdd-bytecoder.py produced empty bytecode for '$serviceName'")
            }
            return bytecode
        } finally {
            Files.deleteIfExists(input)
            Files.deleteIfExists(output)
        }
    }
}
