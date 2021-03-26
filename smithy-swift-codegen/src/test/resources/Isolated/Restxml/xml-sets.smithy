$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml set")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlEnumSet
    ]
}


@idempotent
@http(uri: "/XmlEnumSet", method: "PUT")
operation XmlEnumSet {
    input: XmlEnumSetInputOutput,
    output: XmlEnumSetInputOutput
}


structure XmlEnumSetInputOutput {
    fooEnumSet: FooEnumSet
}

set FooEnumSet {
    member: FooEnum,
}

@enum([
    {
        name: "FOO",
        value: "Foo",
    },
    {
        name: "BAZ",
        value: "Baz",
    },
    {
        name: "BAR",
        value: "Bar",
    },
    {
        name: "ONE",
        value: "1",
    },
    {
        name: "ZERO",
        value: "0",
    },
])
string FooEnum