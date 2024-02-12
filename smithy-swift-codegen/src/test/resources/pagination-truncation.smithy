$version: "1.0"

namespace software.amazon.smithy.swift.codegen.synthetic

use aws.protocols#restXml

@trait(selector: "*")
structure paginationTruncationMember { }

@restXml
service Lambda {
    operations: [ListFunctionsTruncated]
}

list FunctionConfigurationList {
    member: FunctionConfiguration
}

structure FunctionConfiguration {
    functionName: String
}

@paginated(
    inputToken: "marker",
    outputToken: "nextMarker",
    pageSize: "maxItems"
)
@readonly
@http(method: "GET", uri: "/functions/truncated", code: 200)
operation ListFunctionsTruncated {
    input: ListFunctionsRequestTruncated,
    output: ListFunctionsResponseTruncated
}

structure ListFunctionsRequestTruncated {
    @httpQuery("FunctionVersion")
    functionVersion: String,
    @httpQuery("Marker")
    marker: String,
    @httpQuery("MasterRegion")
    masterRegion: String,
    @httpQuery("MaxItems")
    maxItems: Integer,
}

structure ListFunctionsResponseTruncated {
    Functions: FunctionConfigurationList,
    @paginationTruncationMember
    IsTruncated: Boolean,
    nextMarker: String
}