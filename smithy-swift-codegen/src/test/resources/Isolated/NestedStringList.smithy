$version: "1.0"
namespace com.test

use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@restJson1
service Example {
    version: "1.0.0",
    operations: [
        JsonLists
    ]
}

@idempotent
@http(uri: "/JsonLists", method: "PUT")
operation JsonLists {
    input: JsonListsInputOutput,
    output: JsonListsInputOutput
}

apply JsonLists @httpRequestTests([
    {
        id: "RestJsonLists",
        documentation: "Serializes JSON lists",
        protocol: restJson1,
        method: "PUT",
        uri: "/JsonLists",
        body: """
              {
                  "stringList": [
                      "foo",
                      "bar"
                  ],
                  "stringSet": [
                      "foo",
                      "bar"
                  ],
                  "integerList": [
                      1,
                      2
                  ],
                  "booleanList": [
                      true,
                      false
                  ],
                  "timestampList": [
                      1398796238,
                      1398796238
                  ],
                  "enumList": [
                      "Foo",
                      "0"
                  ],
                  "nestedStringList": [
                      [
                          "foo",
                          "bar"
                      ],
                      [
                          "baz",
                          "qux"
                      ]
                  ],
                  "myStructureList": [
                      {
                          "value": "1",
                          "other": "2"
                      },
                      {
                          "value": "3",
                          "other": "4"
                      }
                  ]
              }""",
        bodyMediaType: "application/json",
        headers: {"Content-Type": "application/json"},
        params: {
            "stringList": [
                "foo",
                "bar"
            ],
            "stringSet": [
                "foo",
                "bar"
            ],
            "nestedStringList": [
                [
                    "foo",
                    "bar"
                ],
                [
                    "baz",
                    "qux"
                ]
            ]
        }
    }
])

structure JsonListsInputOutput {
    stringList: StringList,

    stringSet: StringSet,

    nestedStringList: NestedStringList,

}


list StringList {
    member: String,
}

set StringSet {
    member: String,
}

/// A list of lists of strings.
list NestedStringList {
    member: StringList,
}
