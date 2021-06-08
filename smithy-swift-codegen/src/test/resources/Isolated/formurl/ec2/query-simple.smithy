$version: "1.0"

namespace aws.protocoltests.ec2
use aws.api#service
use aws.protocols#ec2Query
use aws.protocols#ec2QueryName
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "EC2 Protocol")
@ec2Query
@xmlNamespace(uri: "https://example.com/")
service AwsEc2 {
    version: "2020-01-08",
    operations: [
        Ec2SimpleInputParams
    ]
}

operation Ec2SimpleInputParams {
    input: Ec2SimpleInputParamsInput
}

structure Ec2SimpleInputParamsInput {
    BarString: String,
    BazBoolean: Boolean,
    BamInt: Integer,
    BooDouble: Double,
    QuxBlob: Blob,
    FzzEnum: FooEnum,

    @ec2QueryName("A")
    HasQueryNameString: String,

    @ec2QueryName("B")
    @xmlName("IgnoreMe")
    HasQueryAndXmlNameString: String,

    @xmlName("c")
    UsesXmlNameString: String,
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