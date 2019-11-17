//
//  HMAC.swift
//  PushValidatoriOS
//
//  Created by Casey Silver on 11/17/19.
//  Copyright © 2019 Casey Silver. All rights reserved.
//
// Taken from https://nabtron.com/commoncrypto-hmac-swift/

import Foundation

/*
 Usage:
 1. Add an ObjC bridging header.
 2. Import <CommonCrypto/CommonCrypto.h> in the header.
 */


//    kCCHmacAlgSHA1,
//    kCCHmacAlgMD5,
//    kCCHmacAlgSHA256,
//    kCCHmacAlgSHA384,
//    kCCHmacAlgSHA512,
//    kCCHmacAlgSHA224
enum HmacAlgorithm {
    case sha1, md5, sha256, sha384, sha512, sha224
    var algorithm: CCHmacAlgorithm {
        var alg = 0
        switch self {
        case .sha1:
            alg = kCCHmacAlgSHA1
        case .md5:
            alg = kCCHmacAlgMD5
        case .sha256:
            alg = kCCHmacAlgSHA256
        case .sha384:
            alg = kCCHmacAlgSHA384
        case .sha512:
            alg = kCCHmacAlgSHA512
        case .sha224:
            alg = kCCHmacAlgSHA224
        }
        return CCHmacAlgorithm(alg)
    }
    var digestLength: Int {
        var len: Int32 = 0
        switch self {
        case .sha1:
            len = CC_SHA1_DIGEST_LENGTH
        case .md5:
            len = CC_MD5_DIGEST_LENGTH
        case .sha256:
            len = CC_SHA256_DIGEST_LENGTH
        case .sha384:
            len = CC_SHA384_DIGEST_LENGTH
        case .sha512:
            len = CC_SHA512_DIGEST_LENGTH
        case .sha224:
            len = CC_SHA224_DIGEST_LENGTH
        }
        return Int(len)
    }
}

extension String {
    func hmac(algorithm: HmacAlgorithm, key: Data) -> String {
        var digest = [UInt8](repeating: 0, count: algorithm.digestLength)
        key.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
            let rawPtr = UnsafeRawPointer(u8Ptr)
            // ... use `rawPtr` ...
            CCHmac(algorithm.algorithm, rawPtr, key.count, self, self.count, &digest)
        }
        //CCHmac(algorithm.algorithm, key, key.count, self, self.count, &digest)
        let data = Data(bytes: digest)
        let base64String = data.base64EncodedString()
        return base64String
    }
}

extension String {
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
