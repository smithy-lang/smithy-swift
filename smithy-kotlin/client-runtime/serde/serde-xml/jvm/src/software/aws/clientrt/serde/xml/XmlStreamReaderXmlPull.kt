/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml

import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.ByteArrayInputStream
import java.lang.IllegalStateException
import java.nio.charset.Charset

private class XmlStreamReaderXmlPull(
    payload: ByteArray,
    charset: Charset = Charsets.UTF_8,
    private val parser: XmlPullParser = xmlPullParserFactory()
) : XmlStreamReader {

    private var peekedToken: XmlToken? = null

    init {
        parser.setInput(ByteArrayInputStream(payload), charset.toString())
    }

    companion object {
        private fun xmlPullParserFactory(): XmlPullParser {
            val factory = XmlPullParserFactory.newInstance(
                "org.xmlpull.mxp1.MXParser", null
            )
            return factory.newPullParser()
        }
    }

    // NOTE: Because of the way peeking is managed, any code in this class wanting to get the next token must call
    // this method rather than calling `parser.nextToken()` direclty.
    override fun nextToken(): XmlToken {
        if (peekedToken != null) {
            val rv = peekedToken
            peekedToken = null
            return rv!!
        }

        try {
            return when (val nt = parser.nextToken()) {
                XmlPullParser.START_DOCUMENT -> nextToken()
                XmlPullParser.END_DOCUMENT -> XmlToken.EndDocument
                XmlPullParser.START_TAG -> XmlToken.BeginElement(parser.name, coerceEmptyStringToNull(parser.namespace))
                XmlPullParser.END_TAG -> XmlToken.EndElement(parser.name, coerceEmptyStringToNull(parser.namespace))
                XmlPullParser.CDSECT, XmlPullParser.COMMENT, XmlPullParser.DOCDECL -> nextToken()
                XmlPullParser.TEXT -> XmlToken.Text(coerceEmptyStringToNull(parser.text))
                else -> throw IllegalStateException("Unhandled tag $nt")
            }
        } catch (e: Exception) {
            throw XmlGenerationException(e)
        }
    }

    //This does one of two things:
    // 1: if the next token is BeginElement, then that node is skipped
    // 2: if the next token is Text or EndElement, read tokens until the end of the current node is exited
    override fun skipNext() {
        val startDepth = parser.depth
        var nt = peek()

        when(nt) {
            // Code path 1
            is XmlToken.BeginElement -> {
                val currentNodeName = nt.name

                var st = nextToken()
                while(st != XmlToken.EndDocument) {
                    if (st is XmlToken.EndElement && parser.depth == startDepth && st.name == currentNodeName) return
                    st = nextToken()
                    require(parser.depth >= startDepth) { "Traversal depth ${parser.depth} exceeded start node depth $startDepth"}
                }
            }
            is XmlToken.EndDocument -> return
            // Code path 2
            else -> {
                while(nt != XmlToken.EndDocument) {
                    nt = nextToken()
                    if (nt is XmlToken.EndElement && parser.depth == startDepth) return
                }
            }
        }
    }

    override fun peek(): XmlToken = when(peekedToken) {
        null -> {
            peekedToken = nextToken()
            peekedToken as XmlToken
        }
        else -> peekedToken as XmlToken
    }

    override fun currentDepth(): Int = parser.depth

    private fun coerceEmptyStringToNull(input: String?): String? =
        if (input?.isBlank() != false) null else input

}
/*
* Creates a [JsonStreamReader] instance
*/
actual fun xmlStreamReader(payload: ByteArray): XmlStreamReader = XmlStreamReaderXmlPull(payload)