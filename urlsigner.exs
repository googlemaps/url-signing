defmodule GoogleUrlSigner do
  def sign(url, key) do
    parsed_url = URI.parse(url)
    full_path = "#{parsed_url.path}?#{parsed_url.query}"

    signature = generate_signature(full_path, key)

    "#{parsed_url.scheme}://#{parsed_url.host}#{full_path}&signature=#{signature}"
  end

  defp generate_signature(path, key) do
    key
    |> url_safe_base64_decode
    |> encrypt(path)
    |> url_safe_base64_encode
  end

  def encrypt(key, data) do
    :crypto.hmac(:sha, key, data)
  end

  def url_safe_base64_decode(base64_string) do
    {:ok, decoded_string} =
      base64_string
      |> String.replace("-", "+")
      |> String.replace("_", "/")
      |> Base.decode64

    decoded_string
  end

  def url_safe_base64_encode(raw) do
    raw
    |> Base.encode64
    |> String.replace("+", "-")
    |> String.replace("/", "_")
    |> String.trim
  end
end

url = "http://maps.google.com/maps/api/geocode/json?address=New+York&sensor=false&client=clientID"
private_key = "vNIXE0xscrmjlyV-12Nj_BvUPaw="

IO.puts GoogleUrlSigner.sign(url, private_key)
