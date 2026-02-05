//
//  KeychainHelper.swift
//  ManifestMe
//
//  Created by Nick Askam on 2/4/26.
//
import Security
import Foundation

class KeychainHelper {
    static let standard = KeychainHelper()
    private let service = "com.manifestme.auth"
    private let account = "authToken"
    
    // Save the token securely
    func save(token: String) {
        let data = Data(token.utf8)
        
        // 1. Create a query for the ACCOUNT (not the data)
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as [String: Any]
        
        // 2. Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // 3. Prepare the new item
        var newAttributes = query
        newAttributes[kSecValueData as String] = data
        
        // 4. Add it and check the result
        let status = SecItemAdd(newAttributes as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("🔐 Keychain: Save Successful!")
        } else if status == errSecDuplicateItem {
            print("🔐 Keychain: Error - Duplicate Item.")
        } else {
            print("🔐 Keychain: Save Error (Status: \(status))")
        }
    }
    
    // Read the token back
    func read() -> String? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne // <--- Crucial fix for reading
        ] as [String: Any]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data {
                return String(data: data, encoding: .utf8)
            }
        } else if status == errSecItemNotFound {
            print("🔐 Keychain: No token found (Clean slate).")
        } else {
            print("🔐 Keychain: Read Error (Status: \(status))")
        }
        
        return nil
    }
    
    // Delete (for Logout)
    func delete() {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
    }
}
