$version: "1.0"

namespace aws.protocoltests.restxml

use aws.api#service
use aws.protocols#restXml
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Xml enums")
@restXml
service RestXml {
    version: "2019-12-16",
    operations: [
        XmlEnums,
        XmlEnumsNested
    ]
}


@idempotent
@http(uri: "/XmlEnums", method: "PUT")
operation XmlEnums {
    input: XmlEnumsInputOutput,
    output: XmlEnumsInputOutput
}

structure XmlEnumsInputOutput {
    fooEnum1: FooEnum,
    fooEnum2: FooEnum,
    fooEnum3: FooEnum,
    fooEnumList: FooEnumList,
}


@idempotent
@http(uri: "/XmlEnumsNested", method: "POST")
operation XmlEnumsNested {
    input: XmlEnumsNestedInputOutput,
    output: XmlEnumsNestedInputOutput
}

structure XmlEnumsNestedInputOutput {
    nestedEnumsList: NestedNestedEnumsList
}

list NestedNestedEnumsList {
    member: NestedEnumsList
}

list NestedEnumsList {
    member: FooEnum
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

list FooEnumList {
    member: FooEnum,
}


//  Todo: sets, maps
//  1.  This will be part of: XmlEnumsInputOutput
//    fooEnumSet: FooEnumSet,
//    fooEnumMap: FooEnumMap,
//
//  2.  Then add this:
//    set FooEnumSet {
//        member: FooEnum,
//    }
//
//    map FooEnumMap {
//        key: String,
//        value: FooEnum,
//    }
//