$version: "2.0"

namespace smithy.swift.tests.EndpointBDD

use aws.protocols#restJson1
use smithy.rules#clientContextParams
use smithy.rules#endpointBdd

// A service whose endpoint rules are only in the endpointBdd trait (no endpointRuleSet), so codegen must
// read endpoint parameters from the BDD and embed its compiled bytecode. The BDD is the Endpoints BDD SEP's
// headers test case.
@clientContextParams(
    Region: { type: "string", documentation: "The region to dispatch this request, eg. `us-east-1`." }
)
@endpointBdd(
    version: "1.1"
    parameters: {
        Region: {
            required: false
            documentation: "The region to dispatch this request, eg. `us-east-1`."
            type: "string"
        }
    }
    conditions: [
        {
            fn: "isSet"
            argv: [
                {
                    ref: "Region"
                }
            ]
        }
    ]
    results: [
        {
            conditions: []
            endpoint: {
                url: "https://{Region}.amazonaws.com"
                properties: {}
                headers: {
                    "x-amz-region": ["{Region}"]
                    "x-amz-multi": ["*", "{Region}"]
                }
            }
            type: "endpoint"
        }
        {
            documentation: "fallback when region is unset"
            conditions: []
            error: "Region must be set to resolve a valid endpoint"
            type: "error"
        }
    ]
    root: 2
    nodeCount: 2
    nodes: "/////wAAAAH/////AAAAAAX14QEF9eEC"
)
@restJson1
service EndpointBDD {
    version: "2022-01-01"
    operations: [
        Echo
    ]
}

@http(method: "PUT", uri: "/echo")
operation Echo {
    input := {
        string: String
    }
    output := {
        string: String
    }
}
