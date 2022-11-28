$version: "2.0"

namespace smithy.example

service Example {
    version: "1.0.0"
    operations: [
        FooOperation
    ]
}

operation FooOperation {
    input: Foo
    output: Foo
}

structure Foo {
    abcs: Abcs
}

intEnum Abcs {
    A = 1
    B = 2
    C = 3
}