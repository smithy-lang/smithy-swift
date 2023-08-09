$version: "2.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml List")
@restXml
service RestXml {
    version: "2023-08-08",
    operations: [
        SimpleScalarProperties
    ]
}


@idempotent
@http(uri: "/SimpleScalarProperties", method: "PUT")
operation SimpleScalarProperties {
    input: SimpleScalarPropertiesInputOutput,
    output: SimpleScalarPropertiesInputOutput
}


structure SimpleScalarPropertiesInputOutput {
    @httpHeader("X-Foo")
    foo: String,

    @default("test")
    stringValue: String,
    @default(false)
    trueBooleanValue: Boolean,
    falseBooleanValue: Boolean,
    byteValue: Byte,
    shortValue: Short,
    @default(5)
    integerValue: Integer,
    longValue: Long,
    @default(2.4)
    floatValue: Float,
    protocol: String,

    @xmlName("DoubleDribble")
    doubleValue: Double,
}