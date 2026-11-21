import AppKit
import SwiftUI
import WebKit

struct OutlineItem: Identifiable, Equatable {
    let id: String
    let level: Int
    let title: String
}

enum ViewMode: String, CaseIterable, Identifiable {
    case rendered = "Rendered"
    case source = "Source"
    var id: String { rawValue }
}

@MainActor
final class ViewerModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published private(set) var mode: ViewMode
    @Published private(set) var outline: [OutlineItem] = []
    @Published private(set) var zoom: Double

    let url: URL?
    let kind: MarkupKind
    let webView: WKWebView
    var canRender: Bool { kind.canRender }

    private var text: String
    private var watcher: FileWatcher?
    private let tempDir: URL
    private var pageCounter = 0
    private var currentPage: URL?
    private var pendingScroll: Double = 0
    private var samePagePaths: Set<String> = []

    private static let zoomKey = "pageZoom"

    init(text: String, url: URL?) {
        self.text = text
        self.url = url
        let kind = MarkupKind(url: url, text: text)
        self.kind = kind
        self.mode = kind.canRender ? .rendered : .source
        let saved = UserDefaults.standard.double(forKey: Self.zoomKey)
        self.zoom = saved > 0 ? saved : 1
        self.webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        self.tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Muview-\(UUID().uuidString)", isDirectory: true)
        super.init()

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        webView.navigationDelegate = self
        webView.allowsMagnification = true
        webView.pageZoom = zoom

        if let url {
            watcher = FileWatcher(url: url) { [weak self] in
                Task { @MainActor in self?.reloadFromDisk() }
            }
        }
        load()
    }

    deinit {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: Actions

    func setMode(_ newMode: ViewMode) {
        guard canRender, newMode != mode else { return }
        mode = newMode
        pendingScroll = 0
        load()
    }

    func toggleMode() { setMode(mode == .rendered ? .source : .rendered) }

    func reloadFromDisk() {
        if let url, let data = try? Data(contentsOf: url) {
            text = MarkupDocument.decode(data)
        }
        webView.evaluateJavaScript("window.scrollY") { [weak self] value, _ in
            guard let self else { return }
            self.pendingScroll = (value as? Double) ?? 0
            self.load()
        }
    }

    func zoomIn() { setZoom(zoom + 0.1) }
    func zoomOut() { setZoom(zoom - 0.1) }
    func zoomReset() { setZoom(1) }

    private func setZoom(_ value: Double) {
        zoom = min(3, max(0.5, (value * 10).rounded() / 10))
        webView.pageZoom = zoom
        UserDefaults.standard.set(zoom, forKey: Self.zoomKey)
    }

    func scroll(to id: String) {
        guard let data = try? JSONEncoder().encode(id), let literal = String(data: data, encoding: .utf8) else { return }
        let js = """
        (function(){var id=\(literal);var e=document.getElementById(id)||document.getElementsByName(id)[0];
        if(e){e.scrollIntoView({behavior:'smooth',block:'start'});}})()
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func find(_ query: String, backwards: Bool = false) {
        guard !query.isEmpty else { return }
        let config = WKFindConfiguration()
        config.backwards = backwards
        config.wraps = true
        config.caseSensitive = false
        webView.find(query, configuration: config) { result in
            if !result.matchFound { NSSound.beep() }
        }
    }

    func printDocument() {
        guard let window = webView.window else { return }
        let info = NSPrintInfo.shared.copy() as! NSPrintInfo
        info.horizontalPagination = .fit
        info.isVerticallyCentered = false
        let op = webView.printOperation(with: info)
        op.view?.frame = webView.bounds
        op.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
    }

    // MARK: Loading

    private func load() {
        let root = URL(fileURLWithPath: "/")
        var paths: Set<String> = []
        if let url {
            paths.insert(url.standardizedFileURL.path)
            paths.insert(url.deletingLastPathComponent().standardizedFileURL.path)
        }

        // HTML documents are shown by WebKit directly so their own resources and scripts work.
        if kind == .html, mode == .rendered, let url {
            samePagePaths = paths
            webView.loadFileURL(url, allowingReadAccessTo: root)
            return
        }

        let html = mode == .rendered
            ? Renderer.renderedPage(kind: kind, text: text, url: url)
            : Renderer.sourcePage(kind: kind, text: text, url: url)

        if let old = currentPage { try? FileManager.default.removeItem(at: old) }
        pageCounter += 1
        let page = tempDir.appendingPathComponent("page-\(pageCounter).html")
        do {
            try html.write(to: page, atomically: true, encoding: .utf8)
            currentPage = page
            paths.insert(page.standardizedFileURL.path)
            samePagePaths = paths
            webView.loadFileURL(page, allowingReadAccessTo: root)
        } catch {
            samePagePaths = paths
            webView.loadHTMLString(html, baseURL: url?.deletingLastPathComponent())
        }
    }

    private var showsOwnHTML: Bool { kind == .html && mode == .rendered }

    private static let outlineJS = """
    (function(){var used={},out=[];
    document.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(function(h){
      var text=(h.textContent||'').trim(); if(!text){return;}
      if(!h.id){var b=text.toLowerCase().replace(/[^\\p{L}\\p{N}\\s_-]/gu,'').trim().replace(/\\s+/g,'-')||'section';
        var n=used[b]||0; used[b]=n+1; var id=n?b+'-'+n:b;
        while(document.getElementById(id)){n++; used[b]=n+1; id=b+'-'+n;}
        h.id=id;}
      out.push({level:parseInt(h.tagName.substring(1)),title:text,id:h.id});});
    return out;})()
    """

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.pageZoom = zoom
        if pendingScroll > 0 {
            webView.evaluateJavaScript("window.scrollTo(0, \(pendingScroll))", completionHandler: nil)
            pendingScroll = 0
        }
        guard mode == .rendered, kind == .markdown || kind == .html else {
            outline = []
            return
        }
        webView.evaluateJavaScript(Self.outlineJS) { [weak self] value, _ in
            guard let self else { return }
            let items = (value as? [[String: Any]] ?? []).compactMap { dict -> OutlineItem? in
                guard let id = dict["id"] as? String, let title = dict["title"] as? String else { return nil }
                let level = (dict["level"] as? Int) ?? Int((dict["level"] as? Double) ?? 1)
                return OutlineItem(id: id, level: level, title: title)
            }
            if items != self.outline { self.outline = items }
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
        decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
    ) {
        // Page scripts only run for HTML documents the user opened; Markdown and source views stay inert.
        preferences.allowsContentJavaScript = showsOwnHTML

        guard navigationAction.navigationType == .linkActivated, let target = navigationAction.request.url else {
            decisionHandler(.allow, preferences)
            return
        }

        if target.isFileURL {
            let path = target.standardizedFileURL.path
            if let fragment = target.fragment, samePagePaths.contains(path) {
                // In-page anchor. Generated pages use <base>, so resolve it ourselves.
                if showsOwnHTML {
                    decisionHandler(.allow, preferences)
                } else {
                    scroll(to: fragment.removingPercentEncoding ?? fragment)
                    decisionHandler(.cancel, preferences)
                }
                return
            }
            var plain = URLComponents(url: target, resolvingAgainstBaseURL: true)
            plain?.fragment = nil
            plain?.query = nil
            let fileURL = plain?.url ?? target
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if MarkupKind.opensInMuview(fileURL) {
                    NSDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { _, _, _ in }
                } else {
                    NSWorkspace.shared.open(fileURL)
                }
            } else {
                NSSound.beep()
            }
            decisionHandler(.cancel, preferences)
            return
        }

        NSWorkspace.shared.open(target)
        decisionHandler(.cancel, preferences)
    }
}

/// Watches one file for edits, including editors that save by replacing the file.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var pending: DispatchWorkItem?
    private var retries = 0

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        start()
    }

    deinit {
        pending?.cancel()
        source?.cancel()
    }

    private func start() {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            // File is mid-replace; try again shortly.
            guard retries < 20 else { return }
            retries += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in self?.start() }
            return
        }
        retries = 0
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend, .delete, .rename], queue: .main)
        src.setEventHandler { [weak self, weak src] in
            guard let self, let src else { return }
            let events = src.data
            if events.contains(.delete) || events.contains(.rename) {
                src.cancel()
                self.source = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.start() }
            }
            self.notify()
        }
        src.setCancelHandler { close(fd) }
        source = src
        src.resume()
    }

    private func notify() {
        pending?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.onChange() }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: item)
    }
}
