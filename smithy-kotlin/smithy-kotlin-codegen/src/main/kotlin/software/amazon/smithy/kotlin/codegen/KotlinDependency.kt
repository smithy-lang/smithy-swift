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
package software.amazon.smithy.kotlin.codegen

import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolDependencyContainer
import software.amazon.smithy.utils.StringUtils

// root namespace for the client-runtime
const val CLIENT_RT_ROOT_NS = "software.aws.clientrt"

// publishing info
const val CLIENT_RT_GROUP = "software.aws.smithy.kotlin"
const val CLIENT_RT_VERSION = "0.0.1"

// See: https://docs.gradle.org/current/userguide/java_library_plugin.html#sec:java_library_configurations_graph
enum class GradleConfiguration {
    // purely internal and not meant to be exposed to consumers.
    Implementation,
    // transitively exported to consumers, for compile.
    Api,
    // only required at compile time, but should not leak into the runtime
    CompileOnly,
    // only required at runtime
    RuntimeOnly,
    // internal test
    TestImplementation,
    // compile time test only
    TestCompileOnly,
    // compile time runtime only
    TestRuntimeOnly;

    override fun toString(): String = StringUtils.uncapitalize(this.name)
}

enum class KotlinDependency(
    val config: GradleConfiguration,
    val namespace: String,
    val group: String,
    val artifact: String,
    val version: String
) : SymbolDependencyContainer {
    // AWS managed dependencies
    CLIENT_RT_CORE(GradleConfiguration.Api, CLIENT_RT_ROOT_NS, CLIENT_RT_GROUP, "client-rt-core", CLIENT_RT_VERSION);

    // External third-party dependencies

    override fun getDependencies(): List<SymbolDependency> {
        val dependency = SymbolDependency.builder()
            .dependencyType(config.name)
            .packageName(namespace)
            .version(version)
            .putProperty("dependency", this)
            .build()
        return listOf(dependency)
    }
}
