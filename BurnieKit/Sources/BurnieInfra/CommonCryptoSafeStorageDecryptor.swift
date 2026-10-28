import BurnieInterface
import CommonCrypto
import Foundation

/// Opens Electron safe storage values as Chromium's OSCrypt writes them on macOS: `v10`, then AES-128-CBC ciphertext
/// with PKCS#7 padding, under a key derived from the app's Keychain password by PBKDF2-HMAC-SHA1. Keeps neither the
/// password nor the key (X-3).
public struct CommonCryptoSafeStorageDecryptor: SafeStorageDecryptor {
    /// OSCrypt's fixed parameters on macOS.
    private static let version = Data("v10".utf8)
    private static let salt = Data("saltysalt".utf8)
    private static let rounds: UInt32 = 1003
    private static let initializationVector = Data(repeating: UInt8(ascii: " "), count: kCCBlockSizeAES128)

    public init() {}

    public func decrypt(_ value: Data, password: Data) -> Data? {
        let ciphertext = value.dropFirst(Self.version.count)
        guard value.starts(with: Self.version), !ciphertext.isEmpty, ciphertext.count.isMultiple(of: kCCBlockSizeAES128),
              let key = Self.key(from: password),
              let padded = Self.decryptBlocks(ciphertext, key: key)
        else { return nil }
        return Self.unpadded(padded)
    }

    private static func key(from password: Data) -> Data? {
        var key = Data(count: kCCKeySizeAES128)
        let keyLength = key.count
        let status = key.withUnsafeMutableBytes { key in
            password.withUnsafeBytes { password in
                salt.withUnsafeBytes { salt in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        password.baseAddress?.assumingMemoryBound(to: CChar.self), password.count,
                        salt.baseAddress?.assumingMemoryBound(to: UInt8.self), salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1), rounds,
                        key.baseAddress?.assumingMemoryBound(to: UInt8.self), keyLength
                    )
                }
            }
        }
        return status == kCCSuccess ? key : nil
    }

    /// The plaintext with its padding still on: CommonCrypto doesn't check padding, `unpadded` does.
    private static func decryptBlocks(_ ciphertext: Data, key: Data) -> Data? {
        var plaintext = Data(count: ciphertext.count)
        let capacity = plaintext.count
        var length = 0
        let status = plaintext.withUnsafeMutableBytes { plaintext in
            ciphertext.withUnsafeBytes { ciphertext in
                key.withUnsafeBytes { key in
                    initializationVector.withUnsafeBytes { initializationVector in
                        CCCrypt(
                            CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(0),
                            key.baseAddress, key.count,
                            initializationVector.baseAddress,
                            ciphertext.baseAddress, ciphertext.count,
                            plaintext.baseAddress, capacity,
                            &length
                        )
                    }
                }
            }
        }
        return status == kCCSuccess ? plaintext.prefix(length) : nil
    }

    /// PKCS#7: the last byte counts the padding bytes, and each of them holds that count. A wrong key or a damaged
    /// ciphertext almost never leaves valid padding, so it opens nothing.
    private static func unpadded(_ padded: Data) -> Data? {
        guard let last = padded.last else { return nil }
        let padding = Int(last)
        guard (1...kCCBlockSizeAES128).contains(padding), padded.suffix(padding).allSatisfy({ $0 == last }) else {
            return nil
        }
        return padded.dropLast(padding)
    }
}
