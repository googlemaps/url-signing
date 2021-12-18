package signurl

import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"fmt"
	"net/url"

	"github.com/pkg/errors"
)

// SignURL signs a request URL with a URL signing secret and returns a usable
// URL with signature appended.
func SignURL(mapUrl string, key string) (string, error) {
	usableKey, err := base64.URLEncoding.DecodeString(key)
	if err != nil {
		return "", errors.Wrap(err, "failed parsing key")
	}

	u, err := url.Parse(mapUrl)
	if err != nil {
		return "", errors.Wrap(err, "failed parsing url")
	}
	toSign := fmt.Sprintf("%s?%s", u.Path, u.RawQuery)

	h := hmac.New(sha1.New, usableKey)
	h.Write([]byte(toSign))
	sig := base64.URLEncoding.EncodeToString(h.Sum(nil))

	signed := fmt.Sprintf("%s://%s%s?%s&signature=%s",
		u.Scheme,
		u.Host,
		u.Path,
		u.RawQuery,
		sig)
	return signed, nil
}
