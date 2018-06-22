import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

val keyString = "YOUR_PRIVATE_KEY"

fun Uri.staticMapsWithSignatureUrl(): String {
    val resource = this.path + '?'.toString() + this.query
    keyString = keyString.replace('-', '+')
    keyString = keyString.replace('_', '/')
    val key = android.util.Base64.decode(keyString, android.util.Base64.DEFAULT)
    val sha1Key = SecretKeySpec(key, "HmacSHA1")
    val mac = Mac.getInstance("HmacSHA1")
    mac.init(sha1Key)
    // compute the binary signature for the request
    val sigBytes = mac.doFinal(resource.toByteArray())
    var signature = android.util.Base64.encodeToString(sigBytes, android.util.Base64.DEFAULT)
    // convert the signature to 'web safe' base 64
    signature = signature.replace('+', '-')
    signature = signature.replace('/', '_')
    return this.scheme + "://" + this.host + resource + "&signature=" + signature
}
