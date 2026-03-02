import CryptoKit
import Foundation
import Security

final class CredentialStore {
    private let fm = FileManager.default
    private let keychainService = "com.hugodesk.github.token"

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
        let account = accountKey(for: projectRoot)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
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

    func saveToken(_ token: String, for projectRoot: String) {
        let account = accountKey(for: projectRoot)
        let encoded = token.data(using: .utf8) ?? Data()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
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

    private func accountKey(for projectRoot: String) -> String {
        let digest = SHA256.hash(data: Data(projectRoot.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func applicationSupportURL() -> URL {
        fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("HugoDesk", isDirectory: true)
    }
}
