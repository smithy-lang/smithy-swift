package software.aws.clientrt.serde.xml

/**
 * Raw tokens produced when reading a JSON document as a stream
 */
sealed class XmlToken {
    /**
     * The opening of an XML element
     */
    data class BeginElement(val name: String, val namespace: String? = null) : XmlToken()

    /**
     * The closing of an XML element
     */
    data class EndElement(val name: String, val namespace: String? = null) : XmlToken()

    /**
     * An XML element text as string
     */
    data class Text(val value: String?) : XmlToken()

    /**
     * A JSON 'null'
     */
    object Null : XmlToken()

    /**
     * The end of the JSON stream to signal that the JSON-encoded value has no more
     * tokens
     */
    object EndDocument : XmlToken()

    override fun toString(): String = when (this) {
        is BeginElement -> "BeginElement"
        is EndElement -> "EndElement"
        is Text -> "Text(${this.value})"
        Null -> "Null"
        EndDocument -> "EndDocument"
    }
}

interface XmlStreamReader {

    /**
     *
     * @throws XmlGenerationException upon any error.
     */
    fun nextToken(): XmlToken

    /**
     * Recursively skip the next token. Meant for discarding unwanted/unrecognized properties in a JSON document
     */
    fun skipNext()

    /**
     * Peek at the next token type
     */
    fun peek(): XmlToken

    /**
     * Return the current node depth of the parser.
     */
    fun currentDepth(): Int
}

/*
* Creates a [JsonStreamReader] instance
*/
internal expect fun xmlStreamReader(payload: ByteArray): XmlStreamReader