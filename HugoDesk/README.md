# HugoDesk

Native macOS app (SwiftUI) for Hugo blog writing and publishing.

## Run

```bash
cd /Users/sexyfeifan/Library/Mobile\ Documents/com~apple~CloudDocs/Hugo/HugoDesk
swift run
```

## Current v1 modules

- Project path and Hugo/Git publish settings
- Markdown editor with live preview and front-matter controls
- Theme configuration panel for `github-style` (including Gitalk and output settings)
- Build / Git status / Commit & Push actions
- GitHub Actions latest workflow status query

## Credential storage

- Remote profile metadata path: `~/Library/Application Support/HugoDesk/profiles/*.json`
- GitHub token path: macOS Keychain (service: `com.hugodesk.github.token`)
- Nothing is written into the blog repo for token/profile metadata.
