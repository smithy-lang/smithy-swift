/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.model.getTrait

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

        // Returns the timestamp format for a given member
        // The logic for determining the format is the following:
        // 1. Use the format defined in the member's timestamp format trait if it exists
        // 2. Use the format defined in the member's target's timestamp format trait if it exists
        // 3. Use the provided default timestamp format
        fun getTimestampFormat(member: Shape, memberTarget: Shape?, defaultTimestampFormat: TimestampFormatTrait.Format): TimestampFormatTrait.Format {
            var formatTrait = defaultTimestampFormat

            member.getTrait<TimestampFormatTrait>()?.let {
                formatTrait = it.format
            } ?: run {
                memberTarget?.getTrait<TimestampFormatTrait>()?.let {
                    formatTrait = it.format
                }
            }

            return formatTrait
        }
    }
}
