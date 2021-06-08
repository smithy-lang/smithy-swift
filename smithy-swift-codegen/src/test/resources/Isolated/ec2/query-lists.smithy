$version: "1.0"

namespace aws.protocoltests.ec2

use aws.api#service
use aws.protocols#ec2Query
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "EC2 Protocol")
@ec2Query
@xmlNamespace(uri: "https://example.com/")
service AwsEc2 {
    version: "2020-01-08",
    operations: [
        Ec2QueryLists
    ]
}

operation Ec2QueryLists {
    input: Ec2QueryListsInput
}

structure Ec2QueryListsInput {
    ListArg: StringList,
    ComplexListArg: GreetingList,

    // Notice that the xmlName on the targeted list member is ignored.
    ListArgWithXmlNameMember: Ec2ListWithXmlName,

    @xmlName("Hi")
    ListArgWithXmlName: Ec2ListWithXmlName,
}

list StringList {
    member: String,
}

list GreetingList {
    member: GreetingStruct
}

structure GreetingStruct {
    hi: String,
}

list Ec2ListWithXmlName {
    @xmlName("item")
    member: String
}