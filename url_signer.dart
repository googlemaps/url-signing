import 'dart:convert';

import 'package:crypto/crypto.dart'; // official dart package

/// Sign a URL with a given crypto key
/// Note that this URL must be properly URL-encoded
String signUrl(String myUrlToSign, String privateKey) {
  // parse the url
  final url = Uri.parse(myUrlToSign);

  final urlPartToSign = '${url.path}?${url.query}';

  // Decode the private key into its binary format
  final decodedKey = base64Url.decode(privateKey);

  // Create a signature using the private key and the URL-encoded
  // string using HMAC SHA1. This signature will be binary.
  final bytes = utf8.encode(urlPartToSign);
  final hmacSha1 = Hmac(sha1, decodedKey);
  final digest = hmacSha1.convert(bytes);

  final encodedSignature = base64Url.encode(digest.bytes);

  return '$myUrlToSign&signature=$encodedSignature';
}

void main() {
  final signedUrl = signUrl("http://maps.google.com/maps/api/geocode/json?address=New+York&sensor=false&client=clientID", 'vNIXE0xscrmjlyV-12Nj_BvUPaw=');
  print(signedUrl);
}
