/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.traits.TimestampFormatTrait

class TimestampHelpers {
    companion object {
        // Returns the corresponding Swift TimestampFormat enum value for the provided format
        fun generateTimestampFormatEnumValue(format: TimestampFormatTrait.Format): String {
            return when (format) {
                TimestampFormatTrait.Format.EPOCH_SECONDS -> "epochSeconds"
                TimestampFormatTrait.Format.DATE_TIME -> "dateTime"
                TimestampFormatTrait.Format.HTTP_DATE -> "httpDate"
                else -> throw Exception("Invalid timestamp format")
            }
        }
    }
}
