#!/usr/bin/ruby
# Test Script for Google Maps API signatures

require 'base64'
require 'openssl'
require 'uri'

module GoogleUrlSigner
  class << self
    def sign(url, key)
      parsed_url = URI.parse(url)
      full_path = "#{parsed_url.path}?#{parsed_url.query}"

      signature = generate_signature(full_path, key)

      "#{parsed_url.scheme}://#{parsed_url.host}#{full_path}&signature=#{signature}"
    end

    private

    def generate_signature(path, key)
      raw_key = url_safe_base64_decode(key)
      digest = OpenSSL::Digest.new('sha1')
      raw_signature = OpenSSL::HMAC.digest(digest, raw_key, path)
      url_safe_base64_encode(raw_signature)
    end

    def url_safe_base64_decode(base64_string)
      Base64.decode64(base64_string.tr('-_', '+/'))
    end

    def url_safe_base64_encode(raw)
      Base64.encode64(raw).tr('+/', '-_').strip
    end
  end
end

# URL to sign
url = 'http://maps.google.com/maps/api/geocode/json?address=New+York&sensor=false&client=clientID'
# Private Key
PRIVATE_KEY = 'vNIXE0xscrmjlyV-12Nj_BvUPaw='

puts GoogleUrlSigner.sign(url, PRIVATE_KEY)
