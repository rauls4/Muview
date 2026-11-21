import Foundation
import cmark_gfm
import cmark_gfm_extensions

enum MarkupKind {
    case markdown, html, svg, xml, text

    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]
    static let htmlExtensions: Set<String> = ["html", "htm", "xhtml"]
    static let xmlExtensions: Set<String> = [
        "xml", "plist", "xib", "storyboard", "rss", "atom", "opml", "xsd", "xsl", "xslt",
        "gpx", "kml", "entitlements", "xcscheme",
    ]

    init(url: URL?, text: String) {
        let ext = url?.pathExtension.lowercased() ?? ""
        if Self.markdownExtensions.contains(ext) { self = .markdown }
        else if Self.htmlExtensions.contains(ext) { self = .html }
        else if ext == "svg" { self = .svg }
        else if Self.xmlExtensions.contains(ext) { self = .xml }
        else {
            // Unknown extension: sniff the content.
            let head = text.prefix(200).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if head.hasPrefix("<!doctype html") || head.hasPrefix("<html") { self = .html }
            else if head.hasPrefix("<?xml") || head.hasPrefix("<") { self = .xml }
            else { self = .text }
        }
    }

    /// Whether there is a rendered view distinct from the source view.
    var canRender: Bool { self == .markdown || self == .html || self == .svg }

    /// File extensions Muview opens itself when a link points at them.
    static func opensInMuview(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return markdownExtensions.contains(ext) || htmlExtensions.contains(ext)
            || xmlExtensions.contains(ext) || ext == "svg" || ext == "txt"
    }
}

enum Renderer {
    // MARK: Pages

    static func renderedPage(kind: MarkupKind, text: String, url: URL?) -> String {
        switch kind {
        case .markdown:
            let (frontMatter, body) = splitFrontMatter(text)
            var html = ""
            if let frontMatter {
                html += "<details class=\"frontmatter\"><summary>Front matter</summary><pre>"
                    + escape(frontMatter) + "</pre></details>\n"
            }
            html += markdownHTML(body)
            return page(body: "<article class=\"doc\">\(html)</article>", url: url)
        case .svg:
            let src = url?.absoluteString ?? ""
            return page(body: "<div class=\"svgwrap\"><img src=\"\(escape(src))\" alt=\"\"></div>", url: url)
        case .html, .xml, .text:
            return sourcePage(kind: kind, text: text, url: url)
        }
    }

    static func sourcePage(kind: MarkupKind, text: String, url: URL?) -> String {
        let highlighted: String
        switch kind {
        case .html, .xml, .svg: highlighted = highlightXML(text)
        case .markdown: highlighted = highlightMarkdown(text)
        case .text: highlighted = escape(text)
        }
        var lineCount = 1
        for ch in text.utf8 where ch == 0x0A { lineCount += 1 }
        let gutter = (1...lineCount).map(String.init).joined(separator: "\n")
        let body = """
        <div class="source"><pre class="gutter">\(gutter)</pre><pre class="code">\(highlighted)</pre></div>
        """
        return page(body: body, url: nil)
    }

    private static func page(body: String, url: URL?) -> String {
        var base = ""
        if let dir = url?.deletingLastPathComponent() {
            base = "<base href=\"\(escape(dir.absoluteString))\">"
        }
        let title = escape(url?.lastPathComponent ?? "Muview")
        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">\(base)
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(title)</title>
        <style>\(Style.css)</style>
        </head><body>
        \(body)
        </body></html>
        """
    }

    // MARK: Markdown

    static func markdownHTML(_ source: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()
        let options = CMARK_OPT_UNSAFE | CMARK_OPT_FOOTNOTES
        guard let parser = cmark_parser_new(options) else { return "<pre>\(escape(source))</pre>" }
        defer { cmark_parser_free(parser) }
        for name in ["table", "strikethrough", "autolink", "tasklist", "tagfilter"] {
            if let ext = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, ext)
            }
        }
        let bytes = Array(source.utf8)
        bytes.withUnsafeBufferPointer { buf in
            buf.baseAddress?.withMemoryRebound(to: CChar.self, capacity: buf.count) {
                cmark_parser_feed(parser, $0, buf.count)
            }
        }
        guard let doc = cmark_parser_finish(parser) else { return "<pre>\(escape(source))</pre>" }
        defer { cmark_node_free(doc) }
        guard let out = cmark_render_html(doc, options, cmark_parser_get_syntax_extensions(parser)) else {
            return "<pre>\(escape(source))</pre>"
        }
        defer { free(out) }
        return String(cString: out)
    }

    /// Splits a leading YAML front-matter block (`---` … `---`) from the body.
    static func splitFrontMatter(_ text: String) -> (String?, String) {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        guard normalized.hasPrefix("---\n") else { return (nil, text) }
        let rest = normalized.dropFirst(4)
        for terminator in ["\n---\n", "\n...\n"] {
            if let r = rest.range(of: terminator) {
                return (String(rest[..<r.lowerBound]), String(rest[r.upperBound...]))
            }
        }
        if rest.hasSuffix("\n---") {
            return (String(rest.dropLast(4)), "")
        }
        return (nil, text)
    }

    // MARK: Source highlighting

    static func escape(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.utf8.count + 16)
        for ch in s.unicodeScalars {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            default: out.unicodeScalars.append(ch)
            }
        }
        return out
    }

    private static let xmlToken = try! NSRegularExpression(
        pattern: #"<!--[\s\S]*?-->|<!\[CDATA\[[\s\S]*?\]\]>|<[!?/]?[A-Za-z][^<>]*>"#)
    private static let tagHead = try! NSRegularExpression(pattern: #"^(<[!?/]?)([\w:.\-]+)"#)
    private static let tagPart = try! NSRegularExpression(
        pattern: #"("[^"]*"|'[^']*')|([\w:.@\-]+)(?=\s*=)"#)

    static func highlightXML(_ text: String) -> String {
        let ns = text as NSString
        var out = ""
        var cursor = 0
        for m in xmlToken.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            out += escape(ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor)))
            let token = ns.substring(with: m.range)
            if token.hasPrefix("<!--") || token.hasPrefix("<![CDATA[") {
                out += "<span class=\"c\">\(escape(token))</span>"
            } else {
                out += highlightTag(token)
            }
            cursor = m.range.location + m.range.length
        }
        out += escape(ns.substring(from: cursor))
        return out
    }

    private static func highlightTag(_ tag: String) -> String {
        let ns = tag as NSString
        let full = NSRange(location: 0, length: ns.length)
        guard let head = tagHead.firstMatch(in: tag, range: full) else { return escape(tag) }
        var out = "<span class=\"p\">\(escape(ns.substring(with: head.range(at: 1))))</span>"
            + "<span class=\"t\">\(escape(ns.substring(with: head.range(at: 2))))</span>"
        var cursor = head.range.length
        let rest = NSRange(location: cursor, length: ns.length - cursor)
        for m in tagPart.matches(in: tag, range: rest) {
            out += escape(ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor)))
            let cls = m.range(at: 1).location != NSNotFound ? "s" : "a"
            out += "<span class=\"\(cls)\">\(escape(ns.substring(with: m.range)))</span>"
            cursor = m.range.location + m.range.length
        }
        out += escape(ns.substring(from: cursor))
        return out
    }

    static func highlightMarkdown(_ text: String) -> String {
        var inFence = false
        var lines: [String] = []
        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isFence = trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~")
            if isFence || inFence {
                lines.append("<span class=\"s\">\(escape(line))</span>")
                if isFence { inFence.toggle() }
            } else if trimmed.hasPrefix("#") {
                lines.append("<span class=\"t\">\(escape(line))</span>")
            } else if trimmed.hasPrefix(">") {
                lines.append("<span class=\"c\">\(escape(line))</span>")
            } else {
                lines.append(escape(line))
            }
        }
        return lines.joined(separator: "\n")
    }
}
