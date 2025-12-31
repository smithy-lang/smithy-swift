package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.aws.traits.ServiceTrait
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.model.getTrait

// Utility function for returning sdkId from service
val ServiceShape.sdkId: String?
    get() = getTrait<ServiceTrait>()?.sdkId
