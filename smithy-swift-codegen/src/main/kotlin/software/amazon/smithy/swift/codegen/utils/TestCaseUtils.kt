package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.protocoltests.traits.HttpMessageTestCase

val HttpMessageTestCase.isSerdeBenchmarkTest: Boolean
    get() = this.tags.contains("serde-benchmark")