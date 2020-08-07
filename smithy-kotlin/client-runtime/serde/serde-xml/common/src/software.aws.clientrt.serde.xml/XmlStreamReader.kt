package software.aws.clientrt.serde.xml

/**
 * Raw tokens produced when reading a XML document as a stream
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
     * The end of the XML stream to signal that the XML-encoded value has no more
     * tokens
     */
    object EndDocument : XmlToken()

    override fun toString(): String = when (this) {
        is BeginElement -> "BeginElement"
        is EndElement -> "EndElement"
        is Text -> "Text(${this.value})"
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
     * Recursively skip the next token. Meant for discarding unwanted/unrecognized nodes in an XML document
     */
    fun skipNext()

    /**
     * Peek at the next token type.  Successive calls will return the same value, meaning there is only one
     * look-ahead at any given time during the parsing of input data.
     */
    fun peek(): XmlToken

    /**
     * Return the current node depth of the parser.
     */
    fun currentDepth(): Int
}

/*
* Creates an [XmlStreamReader] instance
*/
internal expect fun xmlStreamReader(payload: ByteArray): XmlStreamReader