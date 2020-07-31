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

    override fun nextToken(): XmlToken {
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

    private fun coerceEmptyStringToNull(input: String?): String? =
        if (input?.isBlank() != false) null else input

}
/*
* Creates a [JsonStreamReader] instance
*/
actual fun xmlStreamReader(payload: ByteArray): XmlStreamReader = XmlStreamReaderXmlPull(payload)