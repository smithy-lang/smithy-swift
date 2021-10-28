package software.amazon.smithy.swift.cod

import org.commonmark.node.BlockQuote
import org.commonmark.node.FencedCodeBlock
import org.commonmark.node.Heading
import org.commonmark.node.HtmlBlock
import org.commonmark.node.ListBlock
import org.commonmark.node.ThematicBreak
import org.commonmark.parser.Parser
import org.commonmark.renderer.html.HtmlRenderer
import org.jsoup.Jsoup
import org.jsoup.nodes.Node
import org.jsoup.nodes.TextNode
import org.jsoup.safety.Safelist
import org.jsoup.select.NodeTraversor
import org.jsoup.select.NodeVisitor
import software.amazon.smithy.utils.CodeWriter
import software.amazon.smithy.utils.SetUtils
import software.amazon.smithy.utils.StringUtils

// Inspired from Go's implementation:
// https://github.com/aws/smithy-go/blob/main/codegen/smithy-go-codegen/src/main/java/software/amazon/smithy/go/codegen/DocumentationConverter.java
class DocumentationConverter {
    companion object {
        val MARKDOWN_PARSER = Parser.builder()
            .enabledBlockTypes(
                SetUtils.of(
                    Heading::class.java,
                    HtmlBlock::class.java,
                    ThematicBreak::class.java,
                    FencedCodeBlock::class.java,
                    BlockQuote::class.java,
                    ListBlock::class.java
                )
            ).build()
        val SWIFTDOC_ALLOWLIST = Safelist()
            .addTags("code", "pre", "ul", "ol", "li", "a", "br", "h1", "h2", "h3", "h4", "h5", "h6")
            .addAttributes("a", "href")
            .addProtocols("a", "href", "http", "https", "mailto")
        fun convert(docs: String): String {
            val htmlDocs = HtmlRenderer.builder().escapeHtml(false).build().render(MARKDOWN_PARSER.parse(docs))
            val cleanedHtmlDocs = Jsoup.clean(htmlDocs, SWIFTDOC_ALLOWLIST)
            val formatter = FormattingVisitor()
            val body: Node = Jsoup.parse(cleanedHtmlDocs).body()
            NodeTraversor.traverse(formatter, body)
            return formatter.toString().replace("\$", "\$\$")
        }
    }

    class FormattingVisitor(
        val writer: CodeWriter = CodeWriter(),
        var needsListPrefix: Boolean = false,
        var needsBracketsForLink: Boolean = false,
        var shouldStripPrefixWhitespace: Boolean = false,
    ) : NodeVisitor {
        private val TEXT_BLOCK_NODES = SetUtils.of("br", "p", "h1", "h2", "h3", "h4", "h5", "h6")
        private val LIST_BLOCK_NODES = SetUtils.of("ul", "ol")
        private val CODE_BLOCK_NODES = SetUtils.of("pre", "code")

        override fun head(node: Node, depth: Int) {
            val name = node.nodeName()
            if (isTopLevelCodeBlock(node, depth)) {
                writer.indent()
            }

            if (node is TextNode) {
                writeText(node as TextNode)
            } else if (TEXT_BLOCK_NODES.contains(name) || isTopLevelCodeBlock(node, depth)) {
                writeNewline()
                writeIndent()
            } else if (LIST_BLOCK_NODES.contains(name)) {
                writeNewline()
            } else if (name == "li") {
                // We don't actually write out the list prefix here in case the list element
                // starts with one or more text blocks. By deferring writing those out until
                // the first bit of actual text, we can ensure that no intermediary newlines
                // are kept. It also has the added benefit of eliminating empty list elements.
                needsListPrefix = true
            } else if (name == "a") {
                needsBracketsForLink = true
            }
        }

        private fun writeNewline() {
            // While jsoup will strip out redundant whitespace, it will still leave some. If we
            // start a new line then we want to make sure we don't keep any prefixing whitespace.
            shouldStripPrefixWhitespace = true
            writer.write("")
        }
        private fun writeText(node: TextNode) {
            if (node.isBlank) {
                return
            }

            // Docs can have valid $ characters that shouldn't run through formatters.
            var text = node.text().replace("$", "$$")
            if (shouldStripPrefixWhitespace) {
                shouldStripPrefixWhitespace = false
                text = StringUtils.stripStart(text, " \t")
            }
            if (needsBracketsForLink) {
                needsBracketsForLink = false
                text = "[$text]"
            }
            if (needsListPrefix) {
                needsListPrefix = false
                writer.write("")
                writeIndent()
                text = "* " + StringUtils.stripStart(text, " \t")
            }
            writer.writeInline(text)
        }

        fun writeIndent() {
            writer.setNewline("").write("").setNewline("\n")
        }
        private fun isTopLevelCodeBlock(node: Node, depth: Int): Boolean {
            // The node must be a code block node
            if (!CODE_BLOCK_NODES.contains(node.nodeName())) {
                return false
            }

            // It must either have no siblings or its siblings must be separate blocks.
            if (!allSiblingsAreBlocks(node)) {
                return false
            }

            // Depth 0 will always be a "body" element, so depth 1 means it's top level.
            if (depth == 1) {
                return true
            }

            // If its depth is 2, it could still be effectively top level if its parent is a p
            // node whose siblings are all blocks.
            val parent = node.parent()
            return depth == 2 && parent!!.nodeName() == "p" && allSiblingsAreBlocks(parent)
        }

        /**
         * Determines whether a given node's siblings are all text blocks, code blocks, or lists.
         *
         *
         * Siblings that are blank text nodes are skipped.
         *
         * @param node The node whose siblings should be checked.
         * @return true if the node's siblings are blocks, otherwise false.
         */
        private fun allSiblingsAreBlocks(node: Node): Boolean {
            // Find the nearest sibling to the left which is not a blank text node.
            var previous = node.previousSibling()
            while (true) {
                if (previous is TextNode) {
                    if (previous.isBlank) {
                        previous = previous.previousSibling()
                        continue
                    }
                }
                break
            }

            // Find the nearest sibling to the right which is not a blank text node.
            var next = node.nextSibling()
            while (true) {
                if (next is TextNode) {
                    if (next.isBlank) {
                        next = next.nextSibling()
                        continue
                    }
                }
                break
            }
            return (previous == null || isBlockNode(previous)) && (next == null || isBlockNode(next))
        }
        private fun isBlockNode(node: Node): Boolean {
            val name = node.nodeName()
            return (
                TEXT_BLOCK_NODES.contains(name) || LIST_BLOCK_NODES.contains(name) ||
                    CODE_BLOCK_NODES.contains(name)
                )
        }

        override fun tail(node: Node, depth: Int) {
            val name = node.nodeName()
            if (isTopLevelCodeBlock(node, depth)) {
                writer.dedent()
            }

            if (TEXT_BLOCK_NODES.contains(name) || isTopLevelCodeBlock(node, depth) ||
                LIST_BLOCK_NODES.contains(name)
            ) {
                writeNewline()
                writeNewline()
            } else if (name == "a") {
                val url = node.absUrl("href")
                if (!url.isEmpty()) {
                    // godoc can't render links with text bodies, so we simply append the link.
                    // Full links do get rendered.
                    writer.writeInline("(\$L)", url)
                }
            } else if (name == "li") {
                // Clear out the expectation of a list element if the element's body is empty.
                needsListPrefix = false
                writer.write("")
            }
        }

        override fun toString(): String {
            var result = writer.toString()
            if (StringUtils.isBlank(result)) {
                return ""
            }

            // Strip trailing whitespace from every line. We can't use the codewriter for this due to
            // not knowing when a line will end, as we typically build them up over many elements.
            val lines = result.split("\n").dropLastWhile { it.isEmpty() }.toTypedArray()
            for (i in lines.indices) {
                lines[i] = StringUtils.stripEnd(lines[i], " \t")
            }
            result = java.lang.String.join("\n", *lines)

            // Strip out leading and trailing newlines.
            return StringUtils.strip(result, "\n")
        }
    }
}
