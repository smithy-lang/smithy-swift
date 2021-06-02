package software.amazon.smithy.swift.codegen.integration.serde

import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait

class TimeStampFormat {
    companion object {
        fun determineTimestampFormat(member: MemberShape, memberTarget: TimestampShape, defaultTimestampFormat: TimestampFormatTrait.Format): String {
            var formatTrait = defaultTimestampFormat
            if (member.hasTrait(TimestampFormatTrait::class.java)) {
                val timestampFormatTrait = member.getTrait(TimestampFormatTrait::class.java)
                formatTrait = timestampFormatTrait.get().format
            } else if (memberTarget.hasTrait(TimestampFormatTrait::class.java)) {
                val timestampFormatTrait = memberTarget.getTrait(TimestampFormatTrait::class.java)
                formatTrait = timestampFormatTrait.get().format
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
