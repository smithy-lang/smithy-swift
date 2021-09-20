
$version: "1.0"

namespace aws.protocoltests.json

use aws.api#service
use aws.auth#sigv4
use aws.protocols#awsJson1_1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests


@awsJson1_1
@title("Sample Json 1.1 Protocol Service")
service JsonProtocol {
    version: "2018-01-01",
    operations: [
        ListOfMapsOperation
    ]
}

operation ListOfMapsOperation {
    input: ListOfMapsInputOutput,
    output: ListOfMapsInputOutput
}

structure ListOfMapsInputOutput {
    targetMaps: TargetMaps
}

list TargetMaps {
    member: TargetMap
}

map TargetMap {
    key: String,
    value: TargetMapValueList
}

list TargetMapValueList {
    member: String
}