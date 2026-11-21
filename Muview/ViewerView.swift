import SwiftUI
import WebKit

struct ViewerView: View {
    @StateObject private var model: ViewerModel
    @State private var columns: NavigationSplitViewVisibility = .detailOnly
    @State private var query = ""

    init(text: String, url: URL?) {
        _model = StateObject(wrappedValue: ViewerModel(text: text, url: url))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            OutlineView(model: model)
                .navigationSplitViewColumnWidth(min: 180, ideal: 230, max: 360)
        } detail: {
            WebViewHost(webView: model.webView)
                .ignoresSafeArea(edges: .bottom)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("View", selection: Binding(get: { model.mode }, set: { model.setMode($0) })) {
                    ForEach(ViewMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(!model.canRender)
                .help(model.canRender ? "Switch between rendered and source (⌘U)" : "This file type is shown as source")
            }
            ToolbarItemGroup {
                Button { model.zoomOut() } label: { Image(systemName: "minus.magnifyingglass") }
                    .help("Zoom out")
                Button { model.zoomReset() } label: {
                    Text("\(Int((model.zoom * 100).rounded()))%").monospacedDigit().frame(minWidth: 40)
                }
                .help("Actual size")
                Button { model.zoomIn() } label: { Image(systemName: "plus.magnifyingglass") }
                    .help("Zoom in")
            }
        }
        .searchable(text: $query, placement: .toolbar, prompt: "Find")
        .onSubmit(of: .search) { model.find(query) }
        .focusedSceneObject(model)
        .onChange(of: model.outline.isEmpty) { _, isEmpty in
            // Reveal the outline the first time a document turns out to have headings.
            if !isEmpty, columns == .detailOnly { columns = .all }
        }
        .frame(minWidth: 520, minHeight: 360)
    }
}

private struct OutlineView: View {
    @ObservedObject var model: ViewerModel

    var body: some View {
        if model.outline.isEmpty {
            ContentUnavailableView("No Outline", systemImage: "list.bullet.indent",
                                   description: Text("Headings in the document appear here."))
        } else {
            let top = model.outline.map(\.level).min() ?? 1
            List(model.outline) { item in
                Button { model.scroll(to: item.id) } label: {
                    Text(item.title)
                        .lineLimit(2)
                        .font(item.level == top ? .body.weight(.semibold) : .body)
                        .foregroundStyle(item.level - top >= 2 ? .secondary : .primary)
                        .padding(.leading, CGFloat(item.level - top) * 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.sidebar)
        }
    }
}

private struct WebViewHost: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
