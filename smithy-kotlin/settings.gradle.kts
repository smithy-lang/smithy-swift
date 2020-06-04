rootProject.name = "smithy-kotlin"
enableFeaturePreview("GRADLE_METADATA")

include(":smithy-kotlin-codegen")
include(":smithy-kotlin-codegen-test")

include(":client-runtime")
include(":client-runtime:client-rt-core")
include(":client-runtime:utils")
include(":client-runtime:io")
include(":client-runtime:protocol:http")
include(":client-runtime:serde:serde-json")

include(":client-runtime:protocol:http-client-engines:http-client-engine-ktor")
