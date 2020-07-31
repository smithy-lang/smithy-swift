/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.aws.clientrt.serde.xml

import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

fun XmlStreamReader.allTokens(): List<XmlToken> {
    val tokens = mutableListOf<XmlToken>()
    while (true) {
        val token = nextToken()
        tokens.add(token)
        if (token is XmlToken.EndDocument) {
            break
        }
    }
    return tokens
}

fun assertTokensAreEqual(expected: List<XmlToken>, actual: List<XmlToken>) {
    assertEquals(expected.size, actual.size, "unbalanced tokens")
    val pairs = expected.zip(actual)
    pairs.forEach { (exp, act) ->
        assertEquals(exp, act)
    }
}

@OptIn(ExperimentalStdlibApi::class)
class XmlStreamReaderTest {
    @Test
    fun `it deserializes objects`() {
        val payload = """<root><x>1</x><y>2</y></root>""".trimIndent().encodeToByteArray()
        val actual = xmlStreamReader(payload).allTokens()

        val expected = listOf(
            XmlToken.BeginElement("root"),
            XmlToken.BeginElement("x"),
            XmlToken.Text("1"),
            XmlToken.EndElement("x"),
            XmlToken.BeginElement("y"),
            XmlToken.Text("2"),
            XmlToken.EndElement("y"),
            XmlToken.EndElement("root"),
            XmlToken.EndDocument
        )
        assertTokensAreEqual(expected, actual)
    }

    @Test
    fun `garbage in garbage out`() {
        val payload = """you try to parse me once, jokes on me..try twice jokes on you bucko.""".trimIndent().encodeToByteArray()
        assertFailsWith(XmlGenerationException::class) {
            val actual = xmlStreamReader(payload).allTokens()
        }
    }

    @Test
    fun `kitchen sink`() {
        val payload = """
        <root>
          <num>1</num>    
          <str>string</str>
          <list>
            <value>1</value>
            <value>2.3456</value>
            <value>3</value>
          </list>
          <nested>
            <l2>
              <list>
                <x>x</x>
                <value>true</value>
              </list>
            </l2>
            <falsey>false</falsey>
          </nested>
          <null xsi:nil="true"></null>
        </root>""".trimIndent().encodeToByteArray()
        val actual = xmlStreamReader(payload).allTokens()
        println(actual)
        val expected = listOf(
            XmlToken.BeginElement("root", namespace=null),
            XmlToken.Text(null),
            XmlToken.BeginElement("num"),
            XmlToken.Text("1"), 
            XmlToken.EndElement("num"), 
            XmlToken.Text(null), 
            XmlToken.BeginElement("str"), 
            XmlToken.Text("string"), 
            XmlToken.EndElement("str"), 
            XmlToken.Text(null), 
            XmlToken.BeginElement("list"), 
            XmlToken.Text(null), 
            XmlToken.BeginElement("value"), 
            XmlToken.Text("1"), 
            XmlToken.EndElement("value"), 
            XmlToken.Text(null), 
            XmlToken.BeginElement("value"), 
            XmlToken.Text("2.3456"), 
            XmlToken.EndElement("value"), 
            XmlToken.Text(null), 
            XmlToken.BeginElement("value"),
            XmlToken.Text("3"),
            XmlToken.EndElement("value"),
            XmlToken.Text(null),
            XmlToken.EndElement("list"),
            XmlToken.Text(null),
            XmlToken.BeginElement("nested"),
            XmlToken.Text(null),
            XmlToken.BeginElement("l2"),
            XmlToken.Text(null),
            XmlToken.BeginElement("list"),
            XmlToken.Text(null),
            XmlToken.BeginElement("x"),
            XmlToken.Text("x"),
            XmlToken.EndElement("x"),
            XmlToken.Text(null),
            XmlToken.BeginElement("value"),
            XmlToken.Text("true"),
            XmlToken.EndElement("value"),
            XmlToken.Text(null),
            XmlToken.EndElement("list"),
            XmlToken.Text(null),
            XmlToken.EndElement("l2"),
            XmlToken.Text(null),
            XmlToken.BeginElement("falsey"),
            XmlToken.Text("false"),
            XmlToken.EndElement("falsey"),
            XmlToken.Text(null),
            XmlToken.EndElement("nested"),
            XmlToken.Text(null),
            XmlToken.BeginElement("null"),
            XmlToken.EndElement("null"),
            XmlToken.Text(null),
            XmlToken.EndElement("root"),
            XmlToken.EndDocument
        )

        assertTokensAreEqual(expected, actual)
    }

    /*
    @Test
    fun `it skips values recursively`() {
        val payload = """
        {
            "x": 1,
            "unknown": {
                "a": "a",
                "b": "b",
                "c": ["d", "e", "f"],
                "g": {
                    "h": "h",
                    "i": "i"
                }
             },
            "y": 2
        }
        """.trimIndent().encodeToByteArray()
        val reader = xmlStreamReader(payload)
        // skip x
        reader.apply {
            nextToken() // begin obj
            nextToken() // x
            nextToken() // value
        }

        val name = reader.nextToken() as XmlToken.Name
        assertEquals("unknown", name.value)
        reader.skipNext()

        val y = reader.nextToken() as XmlToken.Name
        assertEquals("y", y.value)
    }
     */

    /*
    @Test
    fun `it skips simple values`() {
        val payload = """
        {
            "x": 1,
            "z": "unknown",
            "y": 2
        }
        """.trimIndent().encodeToByteArray()
        val reader = xmlStreamReader(payload)
        // skip x
        reader.apply {
            nextToken() // begin obj
            nextToken() // x
        }
        reader.skipNext()

        val name = reader.nextToken() as XmlToken.Name
        assertEquals("z", name.value)
        reader.skipNext()

        val y = reader.nextToken() as XmlToken.Name
        assertEquals("y", y.value)
    }

     */
}
