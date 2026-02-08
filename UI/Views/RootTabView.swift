import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RootTabView: View {
    @State private var homeViewModel: HomeViewModel
    @State private var historyViewModel: HistoryViewModel
    @State private var settingsViewModel: SettingsViewModel
    @State private var cueDetailViewModel: CueDetailViewModel
    let makeCueHistoryViewModel: () -> CueHistoryViewModel
    let makeRecordingDetailViewModel: () -> RecordingDetailViewModel
    @State private var selectedTab: String = "subjects"
    @SwiftUI.Environment(FeatureAccessContext.self) private var featureAccessContext

    init(
        homeViewModel: HomeViewModel,
        historyViewModel: HistoryViewModel,
        settingsViewModel: SettingsViewModel,
        cueDetailViewModel: CueDetailViewModel,
        makeCueHistoryViewModel: @escaping () -> CueHistoryViewModel,
        makeRecordingDetailViewModel: @escaping () -> RecordingDetailViewModel
    ) {
        _homeViewModel = State(initialValue: homeViewModel)
        _historyViewModel = State(initialValue: historyViewModel)
        _settingsViewModel = State(initialValue: settingsViewModel)
        _cueDetailViewModel = State(initialValue: cueDetailViewModel)
        self.makeCueHistoryViewModel = makeCueHistoryViewModel
        self.makeRecordingDetailViewModel = makeRecordingDetailViewModel
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.sand)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.shadowColor = .clear
        
        // Remove button styling (the white container around toolbar buttons)
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.backgroundImage = nil
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(AppColors.sand)
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HistoryView(
                    viewModel: historyViewModel,
                    cueDetailViewModel: cueDetailViewModel,
                    makeCueHistoryViewModel: makeCueHistoryViewModel,
                    makeRecordingDetailViewModel: makeRecordingDetailViewModel
                )
            }
            .tabItem {
                Image(systemName: "waveform.circle")
                Text(Strings.Tabs.history)
            }
            .tag("history")

            NavigationStack {
                HomeView(
                    viewModel: homeViewModel,
                    cueDetailViewModel: cueDetailViewModel,
                    makeCueHistoryViewModel: makeCueHistoryViewModel,
                    makeRecordingDetailViewModel: makeRecordingDetailViewModel
                )
            }
            .tabItem {
                Image(systemName: "rectangle.stack")
                Text(Strings.Tabs.subjects)
            }
            .tag("subjects")

            NavigationStack {
                SettingsView(viewModel: settingsViewModel)
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text(Strings.Tabs.settings)
            }
            .tag("settings")

            // Developer / debug tab using hammer icon, matching bottom nav style.
            // Visible when the current user + app config satisfy the developer tools gate.
            if featureAccessContext.canSee(DeveloperToolsFeature.gate) {
                NavigationStack {
                    DebugNetworkLogView()
                }
                .tabItem {
                    Image(systemName: "hammer")
                    Text(Strings.Tabs.debug)
                }
                .tag("debug")
            }
        }
        .tint(AppColors.textPrimary)
    }
}

struct DebugNetworkLogView: View {
    @SwiftUI.Environment(NetworkLogStore.self) private var networkLogStore

    var body: some View {
        ZStack {
            AppColors.sand.ignoresSafeArea()

            VStack(spacing: 16) {
                PageHeader(Strings.Debug.networkLogTitle) {
                    Button {
                        networkLogStore.clear()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text(Strings.Debug.clearLogs)
                        }
                        .font(.callout.bold())
                        .foregroundColor(AppColors.textContrast)
                        .padding(.vertical, Spacing.md)
                        .padding(.horizontal, Spacing.xl)
                        .background(AppColors.textPrimary)
                        .cornerRadius(24)
                    }
                    .accessibilityIdentifier("debug.clearLogs")
                }

                // Custom scroll view so we fully control the background
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(
                            networkLogStore.entries.sorted(by: { $0.timestamp > $1.timestamp })
                        ) { entry in
                NavigationLink {
                    NetworkLogDetailView(entry: entry)
                } label: {
                                DebugLogRow(entry: entry, statusColor: statusColor(for: entry.statusCode))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func statusColor(for statusCode: Int?) -> Color {
        guard let statusCode else { return .secondary }
        if (200..<300).contains(statusCode) {
            return AppColors.darkGreen
        } else {
            return AppColors.darkBeige
        }
    }
}

private struct DebugLogRow: View {
    let entry: NetworkLogEntry
    let statusColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
                        Capsule()
                .fill(statusColor)
                .frame(width: 4, height: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.method)
                                    .font(.caption)
                                    .bold()
                        .foregroundColor(statusColor)
                                Text(entry.path)
                                    .font(.caption)
                                    .lineLimit(1)
                        .foregroundColor(AppColors.textPrimary)
                            }

                            HStack(spacing: 8) {
                                if let status = entry.statusCode {
                                    Text("Status \(status)")
                                        .font(.caption2)
                            .foregroundColor(statusColor)
                                }
                                if let ms = entry.durationMs {
                                    Text("\(ms) ms")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NetworkLogDetailView: View {
    let entry: NetworkLogEntry

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Request card
            VStack(alignment: .leading, spacing: 16) {
                section(title: Strings.Debug.requestSectionTitle) {
                    keyValue(Strings.Debug.methodLabel, entry.method)
                    keyValue(Strings.Debug.urlLabel, entry.fullURL)
                    if !entry.requestHeaders.isEmpty {
                        keyValue(Strings.Debug.headersLabel, pretty(headers: entry.requestHeaders))
                    }
                    if let body = entry.requestBodyPreview {
                            jsonBodyLink(Strings.Debug.requestBodyButton, body: body)
                        }
                    }
                }
                .padding()
                .background(AppColors.blue.opacity(0.25))
                .cornerRadius(16)

                // Response card
                VStack(alignment: .leading, spacing: 16) {
                section(title: Strings.Debug.responseSectionTitle) {
                    if let status = entry.statusCode {
                        keyValue(Strings.Debug.statusLabel, "\(status)")
                    }
                    if !entry.responseHeaders.isEmpty {
                        keyValue(Strings.Debug.headersLabel, pretty(headers: entry.responseHeaders))
                    }
                    if let body = entry.responseBodyPreview {
                            jsonBodyLink(Strings.Debug.responseBodyButton, body: body)
                    }
                    if let error = entry.errorDescription {
                        keyValue(Strings.Debug.errorLabel, error)
                    }
                }
                }
                .padding()
                .background(AppColors.cardBackground.opacity(0.7))
                .cornerRadius(16)
            }
            .padding()
        }
        .background(AppColors.sand.ignoresSafeArea())
        .navigationTitle(Strings.Debug.networkLogDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    copyAll()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .imageScale(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
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
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(8)
                .background(AppColors.textContrast.opacity(0.5))
                .cornerRadius(8)
        }
    }

    private func pretty(headers: [String: String]) -> String {
        headers
            .sorted(by: { $0.key.lowercased() < $1.key.lowercased() })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
    }

    private func copyRequest() {
        var parts: [String] = []
        parts.append("REQUEST")
        parts.append("Method: \(entry.method)")
        parts.append("URL: \(entry.fullURL)")
        if !entry.requestHeaders.isEmpty {
            parts.append("Headers:")
            parts.append(pretty(headers: entry.requestHeaders))
        }
        if let body = entry.requestBodyPreview {
            parts.append("Body:")
            parts.append(body)
        }
        copyToPasteboard(parts.joined(separator: "\n\n"))
    }

    private func copyResponse() {
        var parts: [String] = []
        parts.append("RESPONSE")
        if let status = entry.statusCode {
            parts.append("Status: \(status)")
        }
        if !entry.responseHeaders.isEmpty {
            parts.append("Headers:")
            parts.append(pretty(headers: entry.responseHeaders))
        }
        if let body = entry.responseBodyPreview {
            parts.append("Body:")
            parts.append(body)
        }
        if let error = entry.errorDescription {
            parts.append("Error: \(error)")
        }
        copyToPasteboard(parts.joined(separator: "\n\n"))
    }

    private func copyAll() {
        var parts: [String] = []

        // Request
        parts.append("REQUEST")
        parts.append("Method: \(entry.method)")
        parts.append("URL: \(entry.fullURL)")
        if !entry.requestHeaders.isEmpty {
            parts.append("Headers:")
            parts.append(pretty(headers: entry.requestHeaders))
        }
        if let body = entry.requestBodyPreview {
            parts.append("Body:")
            parts.append(body)
        }

        // Spacer
        parts.append("")

        // Response
        parts.append("RESPONSE")
        if let status = entry.statusCode {
            parts.append("Status: \(status)")
        }
        if !entry.responseHeaders.isEmpty {
            parts.append("Headers:")
            parts.append(pretty(headers: entry.responseHeaders))
        }
        if let body = entry.responseBodyPreview {
            parts.append("Body:")
            parts.append(body)
        }
        if let error = entry.errorDescription {
            parts.append("Error: \(error)")
        }

        copyToPasteboard(parts.joined(separator: "\n\n"))
    }

    private func copyToPasteboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
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
        ZStack {
            AppColors.sand.ignoresSafeArea()

            if parseSucceeded {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(nodes) { node in
                        JSONNodeView(node: node, depth: 0)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.Debug.rawBodyTitle)
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    copyRawBody()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .imageScale(.medium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
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

    private func copyRawBody() {
        #if canImport(UIKit)
        UIPasteboard.general.string = rawText
        #endif
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
                    .fill(depthColor(for: depth))
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

    private func depthColor(for depth: Int) -> Color {
        switch depth % 3 {
        case 0: return AppColors.green
        case 1: return AppColors.blue
        default: return AppColors.beige
        }
    }
}

// MARK: - Helpers

private func jsonBodyLink(_ title: String, body: String) -> some View {
    NavigationLink {
        JSONExplorerView(title: title, body: body)
    } label: {
        HStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.callout)
            Text("View JSON body")
                .font(.callout.bold())
        }
    }
    .buttonStyle(PrimaryButtonStyle())
}
