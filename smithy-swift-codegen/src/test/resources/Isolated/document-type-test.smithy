$version: "1.0"
namespace aws.protocoltests.restjson

use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@restJson1
service RestJson {
    version: "1.0.0",
    operations: [
        DocumentType
    ]
}

// Define some shapes shared throughout these test cases.
document Document

apply DocumentType @httpRequestTests([
    {
        id: "DocumentInputWithList",
        documentation: "Serializes document types using a list.",
        protocol: restJson1,
        method: "PUT",
        uri: "/DocumentType",
        body: """
              {
                  "stringValue": "string",
                  "documentValue": [
                      true,
                      "hi",
                      [
                          1,
                          2
                      ],
                      {
                          "foo": {
                              "baz": [
                                  3,
                                  4
                              ]
                          }
                      }
                  ]
              }""",
        bodyMediaType: "application/json",
        headers: {"Content-Type": "application/json"},
        params: {
            stringValue: "string",
            documentValue: [
                true,
                "hi",
                [
                    1,
                    2
                ],
                {
                    "foo": {
                        "baz": [
                            3,
                            4
                        ]
                    }
                }
            ]
        }
    },
])

/// This example serializes a document as part of the payload.
@idempotent
@http(uri: "/DocumentType", method: "PUT")
operation DocumentType {
    input: DocumentTypeInputOutput,
    output: DocumentTypeInputOutput
}

structure DocumentTypeInputOutput {
    stringValue: String,
    documentValue: Document,
}