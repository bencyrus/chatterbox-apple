import SwiftUI

struct RootTabView: View {
    @State private var settingsViewModel: SettingsViewModel
    @State private var isShowingDeveloperPanel: Bool = false
    @State private var isShowingLogsFullScreen: Bool = false

    init(settingsViewModel: SettingsViewModel) {
        _settingsViewModel = State(initialValue: settingsViewModel)
    }

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .navigationTitle(Strings.Home.title)
            }
            .tabItem {
                Image(systemName: "house")
                Text(Strings.Tabs.home)
            }

            NavigationStack {
                SettingsView(viewModel: settingsViewModel)
                    .navigationTitle(Strings.Settings.title)
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text(Strings.Tabs.settings)
            }
        }
        .tint(.white)
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            Button {
                isShowingDeveloperPanel = true
            } label: {
                Image(systemName: "hammer")
                    .foregroundColor(.yellow)
                    .padding(12)
            }
            .accessibilityIdentifier("debug.hammer")
            #else
            if settingsViewModel.isDeveloperUser {
                Button {
                    isShowingDeveloperPanel = true
                } label: {
                    Image(systemName: "hammer")
                        .foregroundColor(.yellow)
                        .padding(12)
                }
                .accessibilityIdentifier("debug.hammer")
            }
            #endif
        }
        .sheet(isPresented: $isShowingDeveloperPanel) {
            DeveloperPanelView {
                // Close drawer and open logs full screen
                isShowingDeveloperPanel = false
                isShowingLogsFullScreen = true
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $isShowingLogsFullScreen) {
            NavigationStack {
                DebugNetworkLogView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                isShowingLogsFullScreen = false
                            }
                        }
                    }
            }
        }
    }
}

struct DeveloperPanelView: View {
    let onShowLogs: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onShowLogs()
                    } label: {
                        HStack {
                            Image(systemName: "terminal")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Logs")
                                    .font(.body)
                                Text("Recent HTTP requests and responses")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Developer")
                }
            }
            .navigationTitle("Developer")
        }
    }
}

struct DebugNetworkLogView: View {
    @Environment(NetworkLogStore.self) private var networkLogStore

    var body: some View {
        NavigationStack {
            List(networkLogStore.entries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                NavigationLink {
                    NetworkLogDetailView(entry: entry)
                } label: {
                    HStack {
                        Capsule()
                            .fill(color(for: entry.statusCode))
                            .frame(width: 4, height: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.method)
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(color(for: entry.statusCode))
                                Text(entry.path)
                                    .font(.caption)
                                    .lineLimit(1)
                            }

                            HStack(spacing: 8) {
                                if let status = entry.statusCode {
                                    Text("Status \(status)")
                                        .font(.caption2)
                                        .foregroundColor(color(for: entry.statusCode))
                                }
                                if let ms = entry.durationMs {
                                    Text("\(ms) ms")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Strings.Debug.networkLogTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        networkLogStore.clear()
                    } label: {
                        Text(Strings.Debug.clearLogs)
                    }
                    .accessibilityIdentifier("debug.clearLogs")
                }
            }
        }
    }

    private func color(for statusCode: Int?) -> Color {
        guard let statusCode else { return .secondary }
        if (200..<300).contains(statusCode) {
            return .green
        } else if (400..<500).contains(statusCode) {
            return .orange
        } else {
            return .red
        }
    }
}

private struct NetworkLogDetailView: View {
    let entry: NetworkLogEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                section(title: Strings.Debug.requestSectionTitle) {
                    keyValue(Strings.Debug.methodLabel, entry.method)
                    keyValue(Strings.Debug.urlLabel, entry.fullURL)
                    if !entry.requestHeaders.isEmpty {
                        keyValue(Strings.Debug.headersLabel, pretty(headers: entry.requestHeaders))
                    }
                    if let body = entry.requestBodyPreview {
                        jsonBodyLink(Strings.Debug.bodyLabel, body: body)
                    }
                }

                section(title: Strings.Debug.responseSectionTitle) {
                    if let status = entry.statusCode {
                        keyValue(Strings.Debug.statusLabel, "\(status)")
                    }
                    if !entry.responseHeaders.isEmpty {
                        keyValue(Strings.Debug.headersLabel, pretty(headers: entry.responseHeaders))
                    }
                    if let body = entry.responseBodyPreview {
                        jsonBodyLink(Strings.Debug.bodyLabel, body: body)
                    }
                    if let error = entry.errorDescription {
                        keyValue(Strings.Debug.errorLabel, error)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(Strings.Debug.networkLogDetailTitle)
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.caption)
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                Text(value)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }

    private func pretty(headers: [String: String]) -> String {
        headers
            .sorted(by: { $0.key.lowercased() < $1.key.lowercased() })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
    }
}

// MARK: - JSON Explorer

private struct JSONNode: Identifiable {
    enum Kind {
        case object
        case array
        case value
    }

    let id = UUID()
    let key: String?
    let kind: Kind
    let valueDescription: String?
    let children: [JSONNode]
}

private struct JSONExplorerView: View {
    let title: String
    let nodes: [JSONNode]
    let rawText: String
    let parseSucceeded: Bool

    init(title: String, body: String) {
        self.title = title
        self.rawText = body

        if
            let data = body.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data)
        {
            let rootNode = JSONExplorerView.makeNode(from: json, key: "root")
            self.nodes = [rootNode]
            self.parseSucceeded = true
        } else {
            self.nodes = []
            self.parseSucceeded = false
        }
    }

    var body: some View {
        Group {
            if parseSucceeded {
                List {
                    ForEach(nodes) { node in
                        JSONNodeView(node: node, depth: 0)
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Raw body")
                            .font(.headline)
                        Text(rawText)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(Strings.Debug.jsonViewerTitle)
    }

    private static func makeNode(from value: Any, key: String?) -> JSONNode {
        if let dict = value as? [String: Any] {
            let children = dict.keys.sorted().map { k in
                makeNode(from: dict[k] as Any, key: k)
            }
            let description = "object (\(dict.count) key\(dict.count == 1 ? "" : "s"))"
            return JSONNode(key: key, kind: .object, valueDescription: description, children: children)
        } else if let array = value as? [Any] {
            let children = array.enumerated().map { index, element in
                makeNode(from: element, key: "[\(index)]")
            }
            let description = "array [\(array.count)]"
            return JSONNode(key: key, kind: .array, valueDescription: description, children: children)
        } else {
            let description: String
            switch value {
            case is NSNull:
                description = "null"
            case let string as String:
                description = "\"\(string)\""
            case let number as NSNumber:
                description = number.stringValue
            default:
                description = String(describing: value)
            }
            return JSONNode(key: key, kind: .value, valueDescription: description, children: [])
        }
    }
}

private struct JSONNodeView: View {
    let node: JSONNode
    let depth: Int

    @State private var isExpanded: Bool

    init(node: JSONNode, depth: Int) {
        self.node = node
        self.depth = depth
        _isExpanded = State(initialValue: depth == 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Capsule()
                    .fill(color(for: depth))
                    .frame(width: 3, height: 24)

                HStack(spacing: 4) {
                    if node.kind != .value {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let key = node.key {
                        Text(key)
                            .font(.system(.caption, design: .monospaced))
                    }

                    if let desc = node.valueDescription {
                        Text(desc)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(.leading, CGFloat(depth) * 12)
            .onTapGesture {
                if node.kind != .value {
                    isExpanded.toggle()
                }
            }

            if isExpanded, !node.children.isEmpty {
                ForEach(node.children) { child in
                    JSONNodeView(node: child, depth: depth + 1)
                }
            }
        }
    }

    private func color(for depth: Int) -> Color {
        switch depth % 4 {
        case 0: return .purple
        case 1: return .blue
        case 2: return .green
        default: return .orange
        }
    }
}

// MARK: - Helpers

private func jsonBodyLink(_ title: String, body: String) -> some View {
    NavigationLink {
        JSONExplorerView(title: title, body: body)
    } label: {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Tap to inspect JSON")
                .font(.footnote)
        }
    }
}

