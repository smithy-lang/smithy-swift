$version: "2.0"

namespace smithy.swift.tests.BigNum

use aws.protocols#restJson1

@restJson1
service BigNum {
    version: "2026-10-12"
    operations: [
        BigNumBody
        BigNumHTTP
    ]
}

bigInteger CustomBigInteger

bigDecimal CustomBigDecimal

list BigIntegerList {
    member: BigInteger
}

map BigDecimalMap {
    key: String
    value: BigDecimal
}

union BigNumUnion {
    bigInteger: BigInteger
    bigDecimal: BigDecimal
}

structure BigNumNested {
    bigInteger: BigInteger
    bigDecimal: BigDecimal
}

@mixin
structure BigNumMembers {
    bigInteger: BigInteger

    bigDecimal: BigDecimal

    customBigInteger: CustomBigInteger

    customBigDecimal: CustomBigDecimal

    list: BigIntegerList

    map: BigDecimalMap

    union: BigNumUnion

    nested: BigNumNested

    @required
    requiredBigInteger: BigInteger

    @required
    requiredBigDecimal: BigDecimal

    @default(0)
    defaultBigInteger: BigInteger

    @default(1.50)
    defaultBigDecimal: BigDecimal
}

@http(method: "POST", uri: "/body")
operation BigNumBody {
    input: BigNumBodyInput
    output: BigNumBodyOutput
}

structure BigNumBodyInput with [BigNumMembers] {}

structure BigNumBodyOutput with [BigNumMembers] {}

@http(method: "POST", uri: "/http/{label}")
operation BigNumHTTP {
    input: BigNumHTTPInput
    output: BigNumHTTPOutput
}

structure BigNumHTTPInput {
    @httpLabel
    @required
    label: BigInteger

    @httpHeader("X-Big-Integer")
    headerBigInteger: BigInteger

    @httpHeader("X-Big-Decimal")
    headerBigDecimal: BigDecimal

    @httpQuery("bigInteger")
    queryBigInteger: BigInteger

    @httpQuery("bigDecimal")
    queryBigDecimal: BigDecimal
}

structure BigNumHTTPOutput {
    @httpHeader("X-Big-Integer")
    headerBigInteger: BigInteger

    @httpHeader("X-Big-Decimal")
    headerBigDecimal: BigDecimal
}
