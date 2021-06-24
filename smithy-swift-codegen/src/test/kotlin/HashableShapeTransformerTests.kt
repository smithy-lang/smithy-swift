import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.HashableShapeTransformer
import software.amazon.smithy.swift.codegen.HashableTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import kotlin.streams.toList

class HashableShapeTransformerTests {

    @Test
    fun `leave non-hashable models unchanged`() {
        val model = javaClass.getResource("hashable-trait-test.smithy").asSmithy()
        val transformed = HashableShapeTransformer.transform(model)
        transformed.shapes().toList().forEach {
            Assertions.assertFalse(transformed.getShape(it.id).get().hasTrait<HashableTrait>())
        }
    }

    @Test
    fun 
}