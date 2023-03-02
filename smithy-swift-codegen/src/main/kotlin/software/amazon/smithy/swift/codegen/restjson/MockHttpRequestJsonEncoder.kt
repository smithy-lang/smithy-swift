package software.amazon.smithy.swift.codegen.restjson

import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.integration.HttpRequestEncoder

class MockHttpRequestJsonEncoder(
    requestEncoderOptions: MutableMap<String, String> = mutableMapOf()
) : HttpRequestEncoder(ClientRuntimeTypes.Serde.JSONEncoder, requestEncoderOptions)