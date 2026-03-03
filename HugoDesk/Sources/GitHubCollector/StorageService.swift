import Foundation

struct StorageService {
    private let fm = FileManager.default

    var defaultBaseDir: URL {
        fm.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/GitHubCollector", isDirectory: true)
    }

    func resolvedBaseDir(customPath: String) -> URL {
        let cleaned = customPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            return defaultBaseDir
        }
        return URL(fileURLWithPath: cleaned, isDirectory: true)
    }

    func dbURL(baseDir: URL) -> URL {
        baseDir.appendingPathComponent("records.json")
    }

    func ignoredIDsURL(baseDir: URL) -> URL {
        baseDir.appendingPathComponent("ignored_ids.json")
    }

    func prepareBaseIfNeeded(baseDir: URL) throws {
        try fm.createDirectory(at: baseDir, withIntermediateDirectories: true)
    }

    func categoryDir(baseDir: URL, _ category: String) -> URL {
        baseDir.appendingPathComponent(safe(category), isDirectory: true)
    }

    func projectDir(baseDir: URL, category: String, project: String) -> URL {
        categoryDir(baseDir: baseDir, category).appendingPathComponent(safe(project), isDirectory: true)
    }

    func saveOrUpdate(_ draft: RepoDraft, baseDir: URL) throws -> RepoRecord {
        try prepareBaseIfNeeded(baseDir: baseDir)

        var records = try loadRecords(baseDir: baseDir)
        let id = draft.identity.fullName.lowercased()
        try removeIgnoredID(id, baseDir: baseDir)

        let pDir = projectDir(baseDir: baseDir, category: draft.category, project: draft.projectName)
        try fm.createDirectory(at: pDir, withIntermediateDirectories: true)

        let infoJSON = pDir.appendingPathComponent("project_info.json")
        let infoMD = pDir.appendingPathComponent("README_COLLECTOR.md")

        let record = RepoRecord(
            id: id,
            owner: draft.identity.owner,
            repo: draft.identity.name,
            projectName: draft.projectName,
            sourceURL: draft.sourceURL.absoluteString,
            descriptionEN: draft.descriptionEN,
            descriptionZH: draft.descriptionZH,
            summaryZH: draft.summaryZH,
            setupGuideZH: draft.setupGuideZH,
            releaseNotesEN: draft.releaseNotesEN,
            releaseNotesZH: draft.releaseNotesZH,
            category: draft.category,
            language: draft.language,
            stars: draft.stars,
            releaseTag: draft.releaseTag,
            releaseAssetName: draft.releaseAssetName,
            releaseAssetURL: draft.releaseAssetURL,
            hasDownloadAsset: draft.hasDownloadAsset,
            localPath: draft.localPath,
            sourceCodePath: draft.sourceCodePath,
            previewImagePath: draft.previewImagePath,
            storageRootPath: baseDir.path,
            infoFilePath: infoMD.path,
            updatedAt: Date()
        )
        return try upsertAndWrite(record, records: &records, baseDir: baseDir, infoJSON: infoJSON, infoMD: infoMD)
    }

    func saveRecord(_ record: RepoRecord, baseDir: URL) throws {
        try prepareBaseIfNeeded(baseDir: baseDir)
        var records = try loadRecords(baseDir: baseDir)
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx] = record
        } else {
            records.append(record)
        }
        try writeRecords(records, baseDir: baseDir)

        let infoPath: URL
        if record.infoFilePath.isEmpty {
            let pDir = projectDir(baseDir: baseDir, category: record.category, project: record.projectName)
            try fm.createDirectory(at: pDir, withIntermediateDirectories: true)
            infoPath = pDir.appendingPathComponent("README_COLLECTOR.md")
        } else {
            infoPath = URL(fileURLWithPath: record.infoFilePath)
        }
        let infoJSON = infoPath.deletingLastPathComponent().appendingPathComponent("project_info.json")
        try writeProjectInfoJSON(record, at: infoJSON)
        try writeProjectInfoMarkdown(record, at: infoPath)
    }

    func deleteRecord(_ record: RepoRecord, baseDir: URL, removeFiles: Bool) throws {
        try prepareBaseIfNeeded(baseDir: baseDir)
        try addIgnoredID(record.id, baseDir: baseDir)
        var records = try loadRecords(baseDir: baseDir)
        records.removeAll { $0.id == record.id }
        try writeRecords(records, baseDir: baseDir)

        if !record.infoFilePath.isEmpty {
            try? fm.removeItem(atPath: record.infoFilePath)
            let infoJSON = URL(fileURLWithPath: record.infoFilePath)
                .deletingLastPathComponent()
                .appendingPathComponent("project_info.json")
            try? fm.removeItem(at: infoJSON)
        }

        guard removeFiles else { return }
        if !record.localPath.isEmpty, fm.fileExists(atPath: record.localPath) {
            try? fm.removeItem(atPath: record.localPath)
        }
        if !record.previewImagePath.isEmpty, fm.fileExists(atPath: record.previewImagePath) {
            try? fm.removeItem(atPath: record.previewImagePath)
        }
        if !record.sourceCodePath.isEmpty, fm.fileExists(atPath: record.sourceCodePath) {
            try? fm.removeItem(atPath: record.sourceCodePath)
        }

        let projectDir = self.projectDir(baseDir: baseDir, category: record.category, project: record.projectName)
        try removeDirectoryIfEmpty(projectDir)
        try removeDirectoryIfEmpty(projectDir.deletingLastPathComponent())
    }

    func loadRecords(baseDir: URL) throws -> [RepoRecord] {
        try prepareBaseIfNeeded(baseDir: baseDir)

        let db = dbURL(baseDir: baseDir)
        let recordsFromDB: [RepoRecord]
        if fm.fileExists(atPath: db.path) {
            let data = try Data(contentsOf: db)
            recordsFromDB = try JSONDecoder.compat.decode([RepoRecord].self, from: data)
        } else {
            recordsFromDB = []
        }

        let fromInfoFiles = try scanInfoFiles(baseDir: baseDir)
        let inferred = try inferRecordsFromPackages(baseDir: baseDir)
        let ignored = try loadIgnoredIDs(baseDir: baseDir)

        var merged: [String: RepoRecord] = [:]
        for r in recordsFromDB + fromInfoFiles + inferred {
            if let existing = merged[r.id] {
                merged[r.id] = existing.updatedAt >= r.updatedAt ? existing : r
            } else {
                merged[r.id] = r
            }
        }

        let sorted = merged.values
            .filter { !ignored.contains($0.id) }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
        try writeRecords(sorted, baseDir: baseDir)
        return sorted
    }

    private func upsertAndWrite(
        _ record: RepoRecord,
        records: inout [RepoRecord],
        baseDir: URL,
        infoJSON: URL,
        infoMD: URL
    ) throws -> RepoRecord {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx] = record
        } else {
            records.append(record)
        }
        try writeRecords(records, baseDir: baseDir)
        try writeProjectInfoJSON(record, at: infoJSON)
        try writeProjectInfoMarkdown(record, at: infoMD)
        return record
    }

    private func writeRecords(_ records: [RepoRecord], baseDir: URL) throws {
        let data = try JSONEncoder.pretty.encode(records.sorted(by: { $0.updatedAt > $1.updatedAt }))
        try data.write(to: dbURL(baseDir: baseDir), options: .atomic)
    }

    private func writeProjectInfoJSON(_ record: RepoRecord, at url: URL) throws {
        let data = try JSONEncoder.pretty.encode(record)
        try data.write(to: url, options: .atomic)
    }

    private func writeProjectInfoMarkdown(_ record: RepoRecord, at url: URL) throws {
        let content = """
        # \(record.projectName)

        - Full Name: \(record.fullName)
        - Category: \(record.category)
        - Stars: \(record.stars)
        - Language: \(record.language)
        - Latest Tag: \(record.releaseTag)
        - Asset: \(record.releaseAssetName)
        - Source: \(record.sourceURL)
        - Local Path: \(record.localPath.isEmpty ? "(none)" : record.localPath)
        - Source Code Path: \(record.sourceCodePath.isEmpty ? "(none)" : record.sourceCodePath)

        ## Summary (ZH)
        \(record.summaryZH)

        ## README.md (Original)
        \(record.descriptionEN)

        ## Description (ZH)
        \(record.descriptionZH)

        ## Setup Guide (ZH)
        \(record.setupGuideZH)

        ## Release Notes (EN)
        \(record.releaseNotesEN)

        ## Release Notes (ZH)
        \(record.releaseNotesZH)
        """
        try content.data(using: .utf8)?.write(to: url, options: .atomic)
    }

    private func scanInfoFiles(baseDir: URL) throws -> [RepoRecord] {
        guard let enumerator = fm.enumerator(
            at: baseDir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var records: [RepoRecord] = []
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent != "project_info.json" { continue }
            do {
                let data = try Data(contentsOf: fileURL)
                var record = try JSONDecoder.compat.decode(RepoRecord.self, from: data)
                if record.storageRootPath.isEmpty {
                    record.storageRootPath = baseDir.path
                }
                records.append(record)
            } catch {
                continue
            }
        }
        return records
    }

    private func inferRecordsFromPackages(baseDir: URL) throws -> [RepoRecord] {
        guard let enumerator = fm.enumerator(
            at: baseDir,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let validSuffixes = [".dmg", ".pkg", ".zip", ".tar.gz"]
        var inferred: [RepoRecord] = []

        for case let fileURL as URL in enumerator {
            let lower = fileURL.lastPathComponent.lowercased()
            guard validSuffixes.contains(where: { lower.hasSuffix($0) }) else { continue }

            let rel = fileURL.path.replacingOccurrences(of: baseDir.path + "/", with: "")
            let comps = rel.split(separator: "/").map(String.init)
            guard comps.count >= 3 else { continue }

            let category = comps[0]
            let project = comps[1]
            let id = "local/\(safe(project).lowercased())"

            let mod = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            let record = RepoRecord(
                id: id,
                owner: "local",
                repo: safe(project).lowercased(),
                projectName: project,
                sourceURL: "",
                descriptionEN: "Detected from existing files in selected storage path.",
                descriptionZH: "从所选存储路径检测到的已有软件文件。",
                summaryZH: "检测到本地历史文件：\(fileURL.lastPathComponent)",
                setupGuideZH: "",
                releaseNotesEN: "",
                releaseNotesZH: "",
                category: category,
                language: "Unknown",
                stars: 0,
                releaseTag: "Unknown",
                releaseAssetName: fileURL.lastPathComponent,
                releaseAssetURL: "",
                hasDownloadAsset: true,
                localPath: fileURL.path,
                sourceCodePath: "",
                previewImagePath: "",
                storageRootPath: baseDir.path,
                infoFilePath: "",
                updatedAt: mod
            )
            inferred.append(record)
        }

        return inferred
    }

    private func safe(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>\n\r")
        return name.components(separatedBy: invalid).joined(separator: "_")
    }

    private func loadIgnoredIDs(baseDir: URL) throws -> Set<String> {
        let url = ignoredIDsURL(baseDir: baseDir)
        guard fm.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        let arr = try JSONDecoder().decode([String].self, from: data)
        return Set(arr)
    }

    private func addIgnoredID(_ id: String, baseDir: URL) throws {
        var set = try loadIgnoredIDs(baseDir: baseDir)
        set.insert(id)
        let data = try JSONEncoder().encode(Array(set).sorted())
        try data.write(to: ignoredIDsURL(baseDir: baseDir), options: .atomic)
    }

    private func removeIgnoredID(_ id: String, baseDir: URL) throws {
        var set = try loadIgnoredIDs(baseDir: baseDir)
        set.remove(id)
        let data = try JSONEncoder().encode(Array(set).sorted())
        try data.write(to: ignoredIDsURL(baseDir: baseDir), options: .atomic)
    }


    private func removeDirectoryIfEmpty(_ url: URL) throws {
        guard fm.fileExists(atPath: url.path) else { return }
        let contents = try fm.contentsOfDirectory(atPath: url.path)
        if contents.isEmpty {
            try? fm.removeItem(at: url)
        }
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

private extension JSONDecoder {
    static var compat: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let stringValue = try? container.decode(String.self)
            if let str = stringValue {
                let iso = ISO8601DateFormatter()
                if let date = iso.date(from: str) {
                    return date
                }
            }
            if let ts = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: ts)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date format")
        }
        return d
    }
}
