<?php
namespace UrlSigner;

/**
 * Sign a URL using a secret key.
 *
 * Port of https://github.com/googlemaps/url-signing/blob/gh-pages/urlsigner.py
 *
 * @param string $input_url The url to sign.
 * @param string $secret Your unique secret key.
 * @return string Signed url
 */

function signUrl($input_url, $secret)
{
    if (!$input_url || !$secret) {
        throw new ErrorException('Both input_url and secret are required');
    }

    $url = parse_url($input_url);
    $url_to_sign = $url['path'] . "?" . $url['query'];

    $decoded_key = base64url_decode($secret);

    $signature = hash_hmac('sha1', $url_to_sign, $decoded_key, true);

    $encoded_signature = base64url_encode($signature);

    $original_url = $url['scheme'] . "://" . $url['host'] . $url['path'] . "?" . $url['query'];

    return $original_url . "&signature=" . $encoded_signature;

}

function base64url_encode($data) {
  return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode($data) {
  return base64_decode(str_pad(strtr($data, '-_', '+/'), strlen($data) % 4, '=', STR_PAD_RIGHT));
}

