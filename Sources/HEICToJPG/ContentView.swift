import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: ConversionModel
    @State private var isDropTarget = false

    private let accent = Color(red: 0.15, green: 0.36, blue: 0.88)

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ready to share.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Your iPhone photos, as JPGs.")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("HEIC → JPG")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(accent.opacity(0.09), in: Capsule())
                    .foregroundStyle(accent)
                    .padding(.top, 5)
            }

            VStack(spacing: 12) {
                Image(systemName: isDropTarget ? "arrow.down.doc.fill" : "photo.on.rectangle.angled")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(accent)
                    .frame(height: 48)
                    .accessibilityHidden(true)
                Text(isDropTarget ? "Drop to convert" : "Drop your HEIC photos here")
                    .font(.system(size: 18, weight: .semibold))
                Text("JPGs are saved in the same folder.")
                    .font(.system(size: 13)).foregroundStyle(.secondary)
                Button(action: model.choosePhotos) {
                    Label("Choose photos…", systemImage: "plus")
                        .padding(.horizontal, 10).padding(.vertical, 3)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                Text("Converts immediately · Originals stay in place")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 24)
            .background(isDropTarget ? accent.opacity(0.10) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(accent.opacity(isDropTarget ? 0.8 : 0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTarget, perform: model.acceptDrop)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("JPEG quality").font(.system(size: 13, weight: .medium))
                        Text("Always full resolution").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("JPEG quality", selection: $model.quality) {
                        Text("Good").tag(0.8)
                        Text("High").tag(0.9)
                        Text("Maximum").tag(1.0)
                    }
                    .labelsHidden().pickerStyle(.segmented).frame(width: 245)
                }
                Divider()
                Toggle(isOn: $model.preserveMetadata) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Keep photo metadata").font(.system(size: 13, weight: .medium))
                        Text("Capture date, camera details, and location when present.")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch).controlSize(.small)
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

            if model.items.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "cursorarrow.click.2").font(.system(size: 23)).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Even quicker from Finder").font(.system(size: 13, weight: .semibold))
                        Text("Select photos, then right-click → Open With → HEIC to JPG.")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                        Text("You can also drop photos onto the app in your Dock.")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 3).padding(.top, 6)
                Spacer(minLength: 0)
            } else {
                results
            }

            HStack(spacing: 5) {
                Image(systemName: "internaldrive")
                Text("Converted on your Mac. No uploads.")
                Spacer()
                Text(".jpg").fontDesign(.monospaced)
            }
            .font(.system(size: 11)).foregroundStyle(.tertiary)
        }
        .padding(28)
        .frame(minWidth: 570, minHeight: 680)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(accent)
        .alert("Couldn’t open a dropped file", isPresented: Binding(
            get: { model.dropError != nil }, set: { if !$0 { model.dropError = nil } }
        )) { Button("OK") { model.dropError = nil } }
        message: { Text(model.dropError ?? "") }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(model.isConverting ? "Converting photos…" : "\(model.outputs.count) JPG\(model.outputs.count == 1 ? "" : "s") saved")
                    .font(.system(size: 13, weight: .semibold))
                if model.failureCount > 0 {
                    Text("\(model.failureCount) failed").font(.system(size: 11)).foregroundStyle(.red)
                }
                Spacer()
                if model.isConverting {
                    Text("\(model.finishedCount) of \(model.items.count)")
                        .font(.system(size: 11)).foregroundStyle(.secondary).monospacedDigit()
                    Button("Stop after current", action: model.stopAfterCurrentPhoto)
                        .disabled(!model.hasPending).controlSize(.small)
                } else {
                    Button("Clear", action: model.clear).buttonStyle(.plain).foregroundStyle(.secondary)
                }
            }
            if model.isConverting {
                ProgressView(value: Double(model.finishedCount), total: Double(max(1, model.items.count)))
                    .progressViewStyle(.linear)
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.items) { item in
                        ResultRow(item: item)
                        if item.id != model.items.last?.id { Divider().padding(.leading, 40) }
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(minHeight: 90, maxHeight: .infinity)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
            if !model.outputs.isEmpty {
                HStack {
                    Text("Existing files are kept; new copies get a numbered name.")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Button("Show in Finder", action: model.revealOutputs).controlSize(.small)
                }
            }
        }
    }
}

private struct ResultRow: View {
    let item: ConversionItem

    var body: some View {
        HStack(spacing: 12) {
            statusIcon.frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.source.lastPathComponent).font(.system(size: 12, weight: .medium)).lineLimit(1).truncationMode(.middle)
                Text(detail).font(.system(size: 11)).foregroundStyle(isFailure ? .red : .secondary)
                    .lineLimit(2).textSelection(.enabled)
            }
            Spacer(minLength: 4)
            if case .saved(let url) = item.status {
                Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.borderless).help("Show \(url.lastPathComponent) in Finder")
                .accessibilityLabel("Show \(url.lastPathComponent) in Finder")
            }
        }
        .padding(.vertical, 10)
        .help(item.source.path)
    }

    @ViewBuilder private var statusIcon: some View {
        switch item.status {
        case .queued: Image(systemName: "clock").foregroundStyle(.secondary)
        case .converting: ProgressView().controlSize(.small)
        case .saved: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed: Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
        case .cancelled: Image(systemName: "minus.circle").foregroundStyle(.secondary)
        }
    }
    private var isFailure: Bool { if case .failed = item.status { return true }; return false }
    private var detail: String {
        switch item.status {
        case .queued: return "Waiting…"
        case .converting: return "Creating JPG…"
        case .saved(let url): return "→ \(url.lastPathComponent)"
        case .failed(let message): return message
        case .cancelled: return "Skipped"
        }
    }
}

