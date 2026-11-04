//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

func cborBigInteger(_ value: String) throws -> CBORType {
    .bigInteger(try BigInteger(value))
}

func cborBigDecimal(_ value: String) throws -> CBORType {
    .bigDecimal(try BigDecimal(value))
}
