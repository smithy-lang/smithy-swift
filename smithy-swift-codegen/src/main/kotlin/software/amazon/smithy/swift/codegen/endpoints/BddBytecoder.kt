/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.endpoints

import software.amazon.smithy.codegen.core.CodegenException
import java.io.IOException
import java.nio.file.Files

/**
 * Runs bdd-bytecoder.py to compile the JSON form of a smithy.rules#endpointBdd trait into the binary
 * bytecode consumed by the CRT BDD engine.
 *
 * The script is bundled with this codegen as a resource. It is a copy of
 * aws-c-sdkutils/compiler/bdd-bytecoder.py and should be updated when the CRT version used by
 * smithy-swift picks up a new version of it.
 */
object BddBytecoder {
    private const val BYTECODER_RESOURCE = "bdd-bytecoder.py"

    // Python 3 is usually `python3`, but only `python` on some platforms (e.g. Windows)
    private val PYTHON_COMMANDS = listOf("python3", "python")

    /**
     * @param traitJson the endpointBdd trait serialized as JSON
     * @param serviceName used only to label temp files and error messages
     * @return the compiled bytecode
     */
    fun compile(
        traitJson: String,
        serviceName: String,
    ): ByteArray {
        val prefix = "bdd-" + serviceName.replace(Regex("[^a-zA-Z0-9._-]"), "_") + "-"
        val bytecoder = Files.createTempFile("bdd-bytecoder-", ".py")
        val input = Files.createTempFile(prefix, ".json")
        val output = Files.createTempFile(prefix, ".bin")
        try {
            val script =
                BddBytecoder::class.java.getResourceAsStream(BYTECODER_RESOURCE)
                    ?: throw CodegenException("Missing bundled resource $BYTECODER_RESOURCE")
            script.use { Files.write(bytecoder, it.readBytes()) }
            Files.writeString(input, traitJson)
            val process = startPython(listOf(bytecoder.toString(), input.toString(), output.toString()))
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
            Files.deleteIfExists(bytecoder)
            Files.deleteIfExists(input)
            Files.deleteIfExists(output)
        }
    }

    /**
     * Starts the first available Python command from [PYTHON_COMMANDS] with the given arguments.
     */
    private fun startPython(args: List<String>): Process {
        var lastError: IOException? = null
        for (python in PYTHON_COMMANDS) {
            try {
                return ProcessBuilder(listOf(python) + args).redirectErrorStream(true).start()
            } catch (e: IOException) {
                lastError = e
            }
        }
        throw CodegenException(
            "Python 3 is required to compile endpointBdd traits, but neither python3 nor python was found on the PATH",
            lastError,
        )
    }
}
