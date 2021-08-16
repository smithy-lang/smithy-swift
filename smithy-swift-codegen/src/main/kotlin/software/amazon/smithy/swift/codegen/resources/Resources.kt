/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.resources

import java.io.File

class Resources {
    companion object {
        fun computeAbsolutePath(relativePath: String, suffixToBeRemoved: String, environmentVariableOverride: String): String {
            if (environmentVariableOverride != null) {
                val userDirPathOverride = System.getenv(environmentVariableOverride)
                if (!userDirPathOverride.isNullOrEmpty()) {
                    return userDirPathOverride
                }
            }

            var userDirPath = System.getProperty("user.dir")
            while (userDirPath.isNotEmpty()) {
                val fileName = userDirPath.removeSuffix("/") + "/" + relativePath
                if (File(fileName).isDirectory) {
                    return fileName.removeSuffix("/$suffixToBeRemoved")
                }
                userDirPath = userDirPath.substring(0, userDirPath.length - 1)
            }
            return ""
        }
    }
}
