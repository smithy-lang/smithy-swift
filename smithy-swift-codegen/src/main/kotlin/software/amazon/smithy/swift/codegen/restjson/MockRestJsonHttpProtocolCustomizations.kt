package software.amazon.smithy.swift.codegen.restjson

import software.amazon.smithy.swift.codegen.integration.ClientProperty
import software.amazon.smithy.swift.codegen.integration.DefaultHttpProtocolCustomizations

class MockRestJsonHttpProtocolCustomizations() : DefaultHttpProtocolCustomizations() {
    override fun getClientProperties(): List<ClientProperty> {
        val properties = mutableListOf<ClientProperty>()
        val requestEncoderOptions = mutableMapOf<String, String>()
        val responseDecoderOptions = mutableMapOf<String, String>()
        requestEncoderOptions["dateEncodingStrategy"] = ".secondsSince1970"
        requestEncoderOptions["nonConformingFloatEncodingStrategy"] = ".convertToString(positiveInfinity: \"Infinity\", negativeInfinity: \"-Infinity\", nan: \"NaN\")"
        responseDecoderOptions["dateDecodingStrategy"] = ".secondsSince1970"
        responseDecoderOptions["nonConformingFloatDecodingStrategy"] = ".convertFromString(positiveInfinity: \"Infinity\", negativeInfinity: \"-Infinity\", nan: \"NaN\")"
        properties.add(MockHttpRequestJsonEncoder(requestEncoderOptions))
        properties.add(MockHttpRequestJsonDecoder(responseDecoderOptions))
        return properties
    }
}