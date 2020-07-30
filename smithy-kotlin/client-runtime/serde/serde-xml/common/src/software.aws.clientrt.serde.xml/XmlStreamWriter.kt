/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml


/**
 * Define an interface to serialization of XML Infoset.
 * This interface abstracts away if serialized XML is XML 1.0 compatible text or
 * other formats of XML 1.0 serializations (such as binary XML for example with WBXML).
 *
 *
 * **PLEASE NOTE:** This interface will be part of XmlPull 1.2 API.
 * It is included as basis for discussion. It may change in any way.
 *
 *
 * Exceptions that may be thrown are: IOException or runtime exception
 * (more runtime exceptions can be thrown but are not declared and as such
 * have no semantics defined for this interface):
 *
 *  * *IllegalArgumentException* - for almost all methods to signal that
 * argument is illegal
 *  * *IllegalStateException* - to signal that call has good arguments but
 * is not expected here (violation of contract) and for features/properties
 * when requesting setting unimplemented feature/property
 * (UnsupportedOperationException would be better but it is not in MIDP)
 *
 *
 *
 * **NOTE:** writing  CDSECT, ENTITY_REF, IGNORABLE_WHITESPACE,
 * PROCESSING_INSTRUCTION, COMMENT, and DOCDECL in some implementations
 * may not be supported (for example when serializing to WBXML).
 * In such case IllegalStateException will be thrown and it is recommended
 * to use an optional feature to signal that implementation is not
 * supporting this kind of output.
 */
interface XmlStreamWriter {

    /**
     * Write &lt;&#63;xml declaration with encoding (if encoding not null)
     * and standalone flag (if standalone not null)
     * This method can only be called just after setOutput.
     */
    fun startDocument(encoding: String? = null, standalone: Boolean? = null)

    /**
     * Finish writing. All unclosed start tags will be closed and output
     * will be flushed. After calling this method no more output can be
     * serialized until next call to setOutput()
     */
    fun endDocument()

    /**
     * Writes a start tag with the given namespace and name.
     * If there is no prefix defined for the given namespace,
     * a prefix will be defined automatically.
     * The explicit prefixes for namespaces can be established by calling setPrefix()
     * immediately before this method.
     * If namespace is null no namespace prefix is printed but just name.
     * If namespace is empty string then serializer will make sure that
     * default empty namespace is declared (in XML 1.0 xmlns='')
     * or throw IllegalStateException if default namespace is already bound
     * to non-empty string.
     */
    fun startTag(name: String, namespace: String? = null): XmlStreamWriter

    /**
     * Write an attribute. Calls to attribute() MUST follow a call to
     * startTag() immediately. If there is no prefix defined for the
     * given namespace, a prefix will be defined automatically.
     * If namespace is null or empty string
     * no namespace prefix is printed but just name.
     */
    fun attribute(name: String, value: String?, namespace: String? = null): XmlStreamWriter

    /**
     * Write end tag. Repetition of namespace and name is just for avoiding errors.
     *
     * **Background:** in kXML endTag had no arguments, and non matching tags were
     * very difficult to find...
     * If namespace is null no namespace prefix is printed but just name.
     * If namespace is empty string then serializer will make sure that
     * default empty namespace is declared (in XML 1.0 xmlns='').
     */
    fun endTag(name: String, namespace: String? = null): XmlStreamWriter

    /**
     * Writes text, where special XML chars are escaped automatically
     */
    fun text(text: String): XmlStreamWriter

    /**
     * XML content will be constructed in this UTF-8 encoded byte array.
     */
    val bytes: ByteArray
}

fun XmlStreamWriter.text(text: Long) {
    this.text(text.toString())
}

fun XmlStreamWriter.text(text: Int) {
    this.text(text.toString())
}

fun XmlStreamWriter.text(text: Double) {
    this.text(text.toString())
}

fun XmlStreamWriter.text(text: Boolean) {
    this.text(text.toString())
}

fun XmlStreamWriter.text(text: Byte) {
    this.text(text.toString())
}

fun XmlStreamWriter.text(text: Short) {
    this.text(text.toString())
}

fun XmlStreamWriter.text(text: Float) {
    this.text(text.toString())
}

/*
* Creates a [XmlStreamWriter] instance to write XML
*/
expect fun xmlStreamWriter(pretty: Boolean = false): XmlStreamWriter