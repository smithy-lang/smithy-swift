$version: "2.0"

namespace smithy.swift.tests

use aws.protocols#awsJson1_0
use smithy.protocols#rpcv2Cbor

@awsJson1_0
service AWSJSONService {
    version: "2022-11-30",
    operations: [GetWidget]
}

@rpcv2Cbor
service RPCv2CBORService {
    version: "2022-11-30",
    operations: [GetWidget]
}

operation GetWidget {
    input: GetWidgetInput
    output: GetWidgetOutput
}

@input
structure GetWidgetInput {
    sensitiveType: SensitiveType
}

@output
structure GetWidgetOutput {
}

structure SensitiveType {
    publicString: String
    publicList: PublicList
    publicMap: PublicMap
    privateString: PrivateString
    privateList: PrivateList
    privateMap: PrivateMap
}

list PublicList {
    member: String
}

map PublicMap {
    key: String
    value: String
}

@sensitive
string PrivateString

list PrivateList {
    member: PrivateString
}

map PrivateMap {
    key: String
    value: PrivateString
}
