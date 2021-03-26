$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml nested set")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlEnumNestedSet
    ]
}

@idempotent
@http(uri: "/XmlEnumNestedSet", method: "PUT")
operation XmlEnumNestedSet {
    input: XmlEnumNestedSetInputOutput,
    output: XmlEnumNestedSetInputOutput
}


structure XmlEnumNestedSetInputOutput {
    fooEnumSet: NestedFooEnumSet
}

set NestedFooEnumSet {
    member: FooEnumSet,
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