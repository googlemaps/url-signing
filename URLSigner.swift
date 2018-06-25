//
//  URLSigner.swift
//
//  Created by Paolo Musolino on 22/06/18.
//

import CryptoSwift // https://github.com/krzyzanowskim/CryptoSwift

class URLSigner: NSObject {
    static func sign(key: String, secret: String) -> URL?{
        let path = "/path/something"
        var secret_key = secret
            secret_key = secret_key.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            if let decodedData = Data(base64Encoded: secret_key)?.bytes, let hmac = try? HMAC(key: decodedData, variant: .sha1).authenticate(Array(path.utf8)), var signature = hmac.toBase64(){
                signature = signature.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
                return URL(string: "URL" + path + "&signature=" + signature)
            }
        return URL(string: "URL" + path)
    }
}
