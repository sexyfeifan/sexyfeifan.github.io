import CryptoKit
import Foundation
import Security

final class CredentialStore {
    private let fm = FileManager.default
    private let githubTokenService = "com.hugodesk.github.token"
    private let aiAPIKeyService = "com.hugodesk.ai.api-key"

    func loadRemoteProfile(for projectRoot: String) -> RemoteProfile? {
        let url = profileURL(for: projectRoot)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(RemoteProfile.self, from: data)
    }

    func saveRemoteProfile(_ profile: RemoteProfile, for projectRoot: String) throws {
        try createAppSupportDirIfNeeded()
        let data = try JSONEncoder().encode(profile)
        try data.write(to: profileURL(for: projectRoot), options: .atomic)
    }

    func loadToken(for projectRoot: String) -> String {
        loadSecret(service: githubTokenService, for: projectRoot)
    }

    func saveToken(_ token: String, for projectRoot: String) {
        saveSecret(token, service: githubTokenService, for: projectRoot)
    }

    func loadAIProfile(for projectRoot: String) -> AIProfile {
        let url = aiProfileURL(for: projectRoot)
        guard let data = try? Data(contentsOf: url),
              let profile = try? JSONDecoder().decode(AIProfile.self, from: data) else {
            return .default
        }
        return profile
    }

    func saveAIProfile(_ profile: AIProfile, for projectRoot: String) throws {
        try createAppSupportDirIfNeeded()
        let data = try JSONEncoder().encode(profile)
        try data.write(to: aiProfileURL(for: projectRoot), options: .atomic)
    }

    func loadAIAPIKey(for projectRoot: String) -> String {
        loadSecret(service: aiAPIKeyService, for: projectRoot)
    }

    func saveAIAPIKey(_ apiKey: String, for projectRoot: String) {
        saveSecret(apiKey, service: aiAPIKeyService, for: projectRoot)
    }

    private func saveSecret(_ secret: String, service: String, for projectRoot: String) {
        let account = accountKey(for: projectRoot)
        let encoded = secret.data(using: .utf8) ?? Data()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [
            kSecValueData as String: encoded
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var create = query
            create[kSecValueData as String] = encoded
            SecItemAdd(create as CFDictionary, nil)
        }
    }

    private func loadSecret(service: String, for projectRoot: String) -> String {
        let account = accountKey(for: projectRoot)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return ""
        }
        guard let data = item as? Data else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    var profileStorageDirectory: URL {
        applicationSupportURL().appendingPathComponent("profiles", isDirectory: true)
    }

    private func createAppSupportDirIfNeeded() throws {
        try fm.createDirectory(at: profileStorageDirectory, withIntermediateDirectories: true)
    }

    private func profileURL(for projectRoot: String) -> URL {
        let key = accountKey(for: projectRoot)
        return profileStorageDirectory.appendingPathComponent("\(key).json")
    }

    private func aiProfileURL(for projectRoot: String) -> URL {
        let key = accountKey(for: projectRoot)
        return profileStorageDirectory.appendingPathComponent("\(key)-ai.json")
    }

    private func accountKey(for projectRoot: String) -> String {
        let digest = SHA256.hash(data: Data(projectRoot.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func applicationSupportURL() -> URL {
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("HugoDesk", isDirectory: true)
    }
}
