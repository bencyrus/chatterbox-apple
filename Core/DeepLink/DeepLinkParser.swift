import Foundation

/// Typed representation of supported deep link intents.
enum DeepLinkIntent: Equatable {
    case magicToken(token: String)
}

/// Parses incoming URLs into typed deep link intents.
///
/// Validation is intentionally conservative: only HTTPS URLs whose host and path
/// match the configured Info.plist values are accepted.
struct DeepLinkParser {
    private struct Config {
        let allowedHosts: Set<String>
        let magicPath: String
    }

    private let config: Config?

    init(bundle: Bundle = .main) {
        self.config = Self.loadConfig(from: bundle)
    }

    func parse(url: URL) -> DeepLinkIntent? {
        guard
            url.scheme?.lowercased() == "https",
            let cfg = config,
            let host = url.host?.lowercased(),
            cfg.allowedHosts.contains(host),
            url.path.lowercased() == cfg.magicPath.lowercased()
        else {
            return nil
        }

        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let tokenItem = components.queryItems?.first(where: { $0.name == "token" }),
            let token = tokenItem.value,
            !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return .magicToken(token: token)
    }

    private static func loadConfig(from bundle: Bundle) -> Config? {
        guard
            let hostsString = bundle.object(forInfoDictionaryKey: "UNIVERSAL_LINK_HOSTS") as? String,
            let magicPathRaw = bundle.object(forInfoDictionaryKey: "MAGIC_LINK_PATH") as? String
        else {
            return nil
        }

        let allowedHosts = hostsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        let magicPath = magicPathRaw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !allowedHosts.isEmpty, magicPath.hasPrefix("/") else {
            return nil
        }

        return Config(
            allowedHosts: Set(allowedHosts),
            magicPath: magicPath
        )
    }
}


