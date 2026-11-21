enum Style {
    static let css = #"""
    :root {
      color-scheme: light dark;
      --bg: #ffffff; --fg: #1f2328; --muted: #656d76; --border: #d8dee4;
      --soft: #f6f8fa; --link: #0969da; --accent: #0969da;
      --tok-tag: #116329; --tok-attr: #0550ae; --tok-str: #953800; --tok-com: #6e7781;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #16181d; --fg: #e3e6ea; --muted: #9198a1; --border: #31363d;
        --soft: #1f2329; --link: #6cb1ff; --accent: #6cb1ff;
        --tok-tag: #7ee787; --tok-attr: #79c0ff; --tok-str: #ffa657; --tok-com: #8b949e;
      }
    }
    * { box-sizing: border-box; }
    html { background: var(--bg); }
    body {
      margin: 0; color: var(--fg); background: var(--bg);
      font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
      -webkit-font-smoothing: antialiased;
    }
    .doc { max-width: 820px; margin: 0 auto; padding: 36px 40px 96px; overflow-wrap: break-word; }
    .doc > :first-child { margin-top: 0; }
    h1, h2, h3, h4, h5, h6 { line-height: 1.25; margin: 1.6em 0 0.6em; font-weight: 650; scroll-margin-top: 16px; }
    h1 { font-size: 2em; padding-bottom: 0.3em; border-bottom: 1px solid var(--border); }
    h2 { font-size: 1.5em; padding-bottom: 0.3em; border-bottom: 1px solid var(--border); }
    h3 { font-size: 1.25em; } h4 { font-size: 1em; } h5 { font-size: 0.9em; }
    h6 { font-size: 0.85em; color: var(--muted); }
    p, ul, ol, blockquote, pre, table, details { margin: 0 0 1em; }
    a { color: var(--link); text-decoration: none; }
    a:hover { text-decoration: underline; }
    img { max-width: 100%; }
    hr { border: 0; border-top: 1px solid var(--border); margin: 2em 0; }
    ul, ol { padding-left: 1.8em; }
    li + li { margin-top: 0.25em; }
    li > ul, li > ol { margin: 0.25em 0 0; }
    li:has(> input[type="checkbox"]) { list-style: none; margin-left: -1.4em; }
    li > input[type="checkbox"] { margin: 0 0.45em 0 0; }
    blockquote { margin-left: 0; padding: 0 1em; color: var(--muted); border-left: 4px solid var(--border); }
    blockquote > :last-child { margin-bottom: 0; }
    code, pre, kbd, .source {
      font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 0.86em;
    }
    code { background: var(--soft); padding: 0.15em 0.4em; border-radius: 5px; }
    pre { background: var(--soft); padding: 14px 16px; border-radius: 8px; overflow-x: auto; line-height: 1.5; }
    pre code { background: none; padding: 0; font-size: 1em; }
    kbd { border: 1px solid var(--border); border-bottom-width: 2px; border-radius: 5px; padding: 0.1em 0.4em; }
    table { border-collapse: collapse; display: block; overflow-x: auto; max-width: 100%; }
    th, td { border: 1px solid var(--border); padding: 6px 13px; }
    th { background: var(--soft); font-weight: 600; }
    del { color: var(--muted); }
    .frontmatter { border: 1px solid var(--border); border-radius: 8px; padding: 8px 14px; color: var(--muted); }
    .frontmatter summary { cursor: default; font-size: 0.85em; }
    .frontmatter pre { margin: 8px 0 4px; }
    .footnotes { font-size: 0.88em; color: var(--muted); border-top: 1px solid var(--border); margin-top: 2.5em; }

    .source { display: flex; align-items: flex-start; min-height: 100vh; font-size: 12.5px; line-height: 1.55; }
    .source pre { margin: 0; background: none; border-radius: 0; padding: 14px 0; overflow: visible; font-size: 1em; line-height: inherit; }
    .source .gutter {
      position: sticky; left: 0; flex: none; min-height: 100vh; text-align: right;
      padding-left: 14px; padding-right: 12px; color: var(--muted); background: var(--soft);
      border-right: 1px solid var(--border); user-select: none; -webkit-user-select: none;
    }
    .source .code { padding-left: 14px; padding-right: 24px; white-space: pre; tab-size: 4; }
    .t { color: var(--tok-tag); } .a { color: var(--tok-attr); }
    .s { color: var(--tok-str); } .c { color: var(--tok-com); } .p { color: var(--muted); }

    .svgwrap {
      min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 32px;
      background-image: conic-gradient(var(--soft) 25%, transparent 0 50%, var(--soft) 0 75%, transparent 0);
      background-size: 20px 20px;
    }
    .svgwrap img { max-width: 100%; max-height: calc(100vh - 64px); }

    @media print {
      .doc { max-width: none; padding: 0; }
      pre { white-space: pre-wrap; }
    }
    """#
}
