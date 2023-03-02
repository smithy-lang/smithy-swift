package software.amazon.smithy.swift.codegen.restjson

import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.integration.HttpResponseDecoder

class MockHttpRequestJsonDecoder(
    requestDecoderOptions: MutableMap<String, String> = mutableMapOf()
) : HttpResponseDecoder(ClientRuntimeTypes.Serde.JSONDecoder, requestDecoderOptions)