$version: "2.0"
namespace com.test

use smithy.protocols#rpcv2Cbor

@rpcv2Cbor
service Example {
    version: "1.0.0",
    operations: [
        ListEvaluators
    ]
}

@http(method: "GET", uri: "/evaluators")
@readonly
operation ListEvaluators {
    input: ListEvaluatorsInput,
    output: ListEvaluatorsOutput
}

@input
structure ListEvaluatorsInput {
    @httpQuery("provider")
    provider: String,

    @httpQuery("maxResults")
    maxResults: Integer,

    @httpQuery("nextToken")
    nextToken: String
}

@output
structure ListEvaluatorsOutput {
    nextToken: String
}
