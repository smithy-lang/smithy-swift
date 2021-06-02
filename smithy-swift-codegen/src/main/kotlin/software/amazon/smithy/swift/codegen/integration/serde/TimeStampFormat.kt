package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.model.getTrait

class TimeStampFormat {
    companion object {
        fun determineTimestampFormat(member: MemberShape, memberTarget: TimestampShape, defaultTimestampFormat: TimestampFormatTrait.Format): String {
            var formatTrait = defaultTimestampFormat

            member.getTrait<TimestampFormatTrait>()?.let {
                formatTrait = it.format
            } ?: run {
                memberTarget.getTrait<TimestampFormatTrait>()?.let {
                    formatTrait = it.format
                }
            }

            when (formatTrait) {
                TimestampFormatTrait.Format.EPOCH_SECONDS -> {
                    return "epochSeconds"
                }
                TimestampFormatTrait.Format.DATE_TIME -> {
                    return "dateTime"
                }
                TimestampFormatTrait.Format.HTTP_DATE -> {
                    return "httpDate"
                }
            }
            return "unknownFormat_ErrorInSmithyModel_or_Codegen"
        }
    }
}
