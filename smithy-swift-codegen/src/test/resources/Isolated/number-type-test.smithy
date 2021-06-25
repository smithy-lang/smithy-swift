$version: "1.0"
namespace aws.protocoltests.restjson

use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@restJson1
service RestJson {
    version: "1.0.0",
    operations: [
        HttpRequestWithFloatLabels
    ]
}


apply HttpRequestWithFloatLabels @httpRequestTests([
    {
        id: "RestJsonSupportsNaNFloatLabels",
        documentation: "Supports handling NaN float label values.",
        protocol: restJson1,
        method: "GET",
        uri: "/FloatHttpLabels/NaN/NaN",
        body: "",
        params: {
            float: "NaN",
            double: "NaN",
        }
    },
    {
        id: "RestJsonSupportsInfinityFloatLabels",
        documentation: "Supports handling Infinity float label values.",
        protocol: restJson1,
        method: "GET",
        uri: "/FloatHttpLabels/Infinity/Infinity",
        body: "",
        params: {
            float: "Infinity",
            double: "Infinity",
        }
    },
    {
        id: "RestJsonSupportsNegativeInfinityFloatLabels",
        documentation: "Supports handling -Infinity float label values.",
        protocol: restJson1,
        method: "GET",
        uri: "/FloatHttpLabels/-Infinity/-Infinity",
        body: "",
        params: {
            float: "-Infinity",
            double: "-Infinity",
        }
    },
])

@readonly
@http(method: "GET", uri: "/FloatHttpLabels/{float}/{double}")
operation HttpRequestWithFloatLabels {
    input: HttpRequestWithFloatLabelsInput
}

structure HttpRequestWithFloatLabelsInput {
    @httpLabel
    @required
    float: Float,

    @httpLabel
    @required
    double: Double,
}