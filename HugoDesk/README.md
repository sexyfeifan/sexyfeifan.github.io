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
- New post wizard with custom filename and automatic pinyin-style slug suggestion
- Post delete action and richer markdown editing toolbar
- Image upload into posts (`static/images/uploads`) and theme settings (`static/images/settings`)
- Auto-fix local image links before publish so pushed posts render images correctly
- Theme configuration panel for `github-style` (including Gitalk and output settings)
- Build / Git status / Commit & Push actions
- GitHub Actions latest workflow status query
- Publish preflight checks (remote/token/workflow/content checks)

## Credential storage

- Project local config bundle: `<blog-root>/.hugodesk.local.json` (remote profile, tokens, AI settings, project settings, theme snapshot)
- Latest artifacts (current version only): `HugoDesk/latest/`
- Historical backups (all versions): `<blog-root>/HugoDeskArchive/versions/<version>/`
- Legacy compatibility storage still available:
  - `~/Library/Application Support/HugoDesk/profiles/*.json`
  - macOS Keychain (`com.hugodesk.github.token`, `com.hugodesk.ai.api-key`)
