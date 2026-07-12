//
//  TokenStore.swift
//  TelemetryDeck Stats
//

import Foundation
import Security

protocol TokenStoring: Sendable {
    func readToken() -> String?
    func saveToken(_ token: String?) throws
}

struct KeychainTokenStore: TokenStoring {
    private let service = "nl.wesleydegroot.TelemetryDeckStats"
    private let account = "api-token"

    func readToken() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func saveToken(_ token: String?) throws {
        guard let token else {
            SecItemDelete(baseQuery as CFDictionary)
            return
        }

        let attributes: [String: Any] = [
            kSecValueData as String: Data(token.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        guard updateStatus == errSecItemNotFound else {
            guard updateStatus == errSecSuccess else {
                throw TokenStoreError.unhandledStatus(updateStatus)
            }
            return
        }

        var query = baseQuery
        query.merge(attributes) { _, new in new }
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw TokenStoreError.unhandledStatus(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum TokenStoreError: Error {
    case unhandledStatus(OSStatus)
}
