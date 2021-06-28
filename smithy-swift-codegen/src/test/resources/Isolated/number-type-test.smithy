$version: "1.0"
namespace aws.protocoltests.restjson

use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@restJson1
service RestJson {
    version: "1.0.0",
    operations: [
        HttpRequestWithFloatLabels,
        InputAndOutputWithHeaders
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

@http(uri: "/InputAndOutputWithHeaders", method: "POST")
operation InputAndOutputWithHeaders {
    input: InputAndOutputWithHeadersIO,
    output: InputAndOutputWithHeadersIO
}

apply InputAndOutputWithHeaders @httpResponseTests([
    {
        id: "RestJsonSupportsNaNFloatHeaderOutputs",
        documentation: "Supports handling NaN float header values.",
        protocol: restJson1,
        code: 200,
        headers: {
            "X-Float": "NaN",
            "X-Double": "NaN",
        },
        params: {
            headerFloat: "NaN",
            headerDouble: "NaN",
        }
    }
])

structure InputAndOutputWithHeadersIO {

    @httpHeader("X-Float")
    headerFloat: Float,

    @httpHeader("X-Double")
    headerDouble: Double,

}