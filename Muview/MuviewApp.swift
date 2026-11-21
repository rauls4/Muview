import SwiftUI
import UniformTypeIdentifiers

@main
struct MuviewApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkupDocument.self) { file in
            ViewerView(text: file.document.text, url: file.fileURL)
        }
        .defaultSize(width: 980, height: 760)
        .commands { ViewerCommands() }
    }
}

/// Read-only document: Muview never writes files.
struct MarkupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [
        UTType(importedAs: "net.daringfireball.markdown"),
        .html, .xml, .svg, .json, .yaml, .propertyList, .plainText, .text,
    ]
    static let writableContentTypes: [UTType] = []

    var text: String

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        text = MarkupDocument.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }

    static func decode(_ data: Data) -> String {
        if let s = String(data: data, encoding: .utf8) { return s }
        if let s = String(data: data, encoding: .utf16) { return s }
        return String(decoding: data, as: UTF8.self)
    }
}

struct ViewerCommands: Commands {
    @FocusedObject private var model: ViewerModel?

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button(model?.mode == .source ? "Show Rendered" : "Show Source") {
                model?.toggleMode()
            }
            .keyboardShortcut("u", modifiers: .command)
            .disabled(model?.canRender != true)

            Button("Reload") { model?.reloadFromDisk() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(model == nil)

            Divider()

            Button("Zoom In") { model?.zoomIn() }
                .keyboardShortcut("=", modifiers: .command)
                .disabled(model == nil)
            Button("Zoom Out") { model?.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(model == nil)
            Button("Actual Size") { model?.zoomReset() }
                .keyboardShortcut("0", modifiers: .command)
                .disabled(model == nil)

            Divider()
        }
        CommandGroup(replacing: .printItem) {
            Button("Print…") { model?.printDocument() }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(model == nil)
        }
    }
}
