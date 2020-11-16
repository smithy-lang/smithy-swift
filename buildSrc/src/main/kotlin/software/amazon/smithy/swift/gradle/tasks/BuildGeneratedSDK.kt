/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.gradle.tasks

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException;
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.TaskAction
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

open class BuildGeneratedSDK : DefaultTask() {
    @get:Input
    var pathToGeneratedSDK = "."

    @TaskAction
    fun runSwiftBuild() {
        if (swiftBuildToolsExist()) {
            val swiftBuildCmd = "swift build"
            swiftBuildCmd.runAsProcess(). let {
                if (it == null) {
                    throw GradleException("Running $swiftBuildCmd returned null unexpectedly.")
                }
                val swiftBuildCmdOutput = it.inputStream.bufferedReader().readText()
                println("swift build output: \n $swiftBuildCmdOutput")
                if (it.exitValue() != 0) {
                    it.destroy()
                    throw GradleException("Non-Zero exit code for process: $swiftBuildCmd")
                }
                it.destroy()
            }
        }
        else {
            println("warning: Could not find swift build tools in host machine. Skip building generated SDK.")
        }
    }

    private fun swiftBuildToolsExist(): Boolean {
        val swiftVersionCmd = "swift --version"
        swiftVersionCmd.runAsProcess().let {
            if (it == null) {
                return false
            }
            if (it.exitValue() != 0) {
                it.destroy()
                return false
            }
            val swiftBuildToolsVersion = it.inputStream.bufferedReader().readText()
            it.destroy()
            println("Swift build tools version found: $swiftBuildToolsVersion")
            return true
        }
    }

    private fun String.runAsProcess(
        workingDir: File = File(pathToGeneratedSDK),
        timeoutInMinutes: Long = 3
    ): Process? = try {
        println("process working directory exists: ${workingDir.exists()}")
        ProcessBuilder(*split(" ").toTypedArray())
            .directory(workingDir)
            .redirectOutput(ProcessBuilder.Redirect.PIPE)
            .redirectError(ProcessBuilder.Redirect.PIPE)
            .start()
            .apply { waitFor(timeoutInMinutes, TimeUnit.MINUTES) }
    } catch (e: IOException) {
        e.printStackTrace()
        null
    }
}