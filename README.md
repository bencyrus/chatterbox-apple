## Chatterbox iOS App

Status: current
Last verified: 2025-10-18

### Overview

- SwiftUI iOS app (iOS 17) with MVVM + Use Cases + Repository.
- Single Xcode project at repo root: `Chatterbox.xcodeproj`.
- Networking via `URLSession`; tokens stored securely in Keychain.

### Requirements

- Xcode 15+
- iOS 17 simulator or device

### Getting started

1. Open `Chatterbox.xcodeproj` in Xcode.
2. Choose an iOS 17 simulator and Run.

### Directory layout

- `App/` — App entry and composition
- `Core/` — Config, Networking, Security, Localization helpers
- `Features/` — Feature modules (e.g., Auth)
- `UI/` — Reusable views and theme
- `Resources/` — Localized strings and assets
- `docs/` — Project docs (architecture, auth)

### Docs

- Architecture: [`docs/architecture.md`](docs/architecture.md)
- Auth: [`docs/auth.md`](docs/auth.md)

### Notes

- No tests included by design (can be reintroduced later).
