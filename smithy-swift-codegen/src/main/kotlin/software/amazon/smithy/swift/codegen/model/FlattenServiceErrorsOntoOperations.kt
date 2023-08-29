package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.ServiceShape

object FlattenServiceErrorsOntoOperations {
    /**
     * Puts error structures defined at service level to every operation under that service.
     * Pre-processing is required to ensure operations correctly model service errors in addition to operation errors.
     */
    fun transform(model: Model, service: ServiceShape): Model {
        // Get service errors. If none exist, return unmodified model
        val serviceErrors = if (service.errors == null || service.errors.isEmpty()) return model else service.errors

        val topDownIndex: TopDownIndex = TopDownIndex.of(model)
        val operations = topDownIndex.getContainedOperations(service)
        val modelBuilder: Model.Builder = model.toBuilder()

        // Append service errors to each and every operation
        for (op in operations) {
            modelBuilder.addShape(
                op.toBuilder().addErrors(serviceErrors).build()
            )
        }

        return modelBuilder.build()
    }
}
