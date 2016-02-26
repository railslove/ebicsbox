class Blebics::PemConverter
  attr_accessor :key, :public_key, :private_key

  def initialize(pem)
    self.key = OpenSSL::PKey::RSA.new(pem)
    self.public_key = extract_public_key
    self.private_key = extract_private_key
  end

  def key_pair
    return if self.public_key.nil? || self.private_key.nil?
    @key_pair ||= KeyPair.new(self.public_key, self.private_key)
  end

  private

  def extract_public_key
    public_key = self.key.public_key.to_pem
    public_key = replace_public_key_headers(public_key)
    public_key_to_X509(public_key)
  end

  def extract_private_key
    return unless key.private?
    key = replace_private_key_headers(self.key.to_pem)
    private_key_to_pkcs(key)
  end

  def public_key_to_X509(publicKeyPem)
    encoded = parse_base64(publicKeyPem)
    keySpec = X509EncodedKeySpec.new(encoded)
    key_factory.generatePublic(keySpec)
  end

  def private_key_to_pkcs(privKeyPEM)
    encoded = parse_base64(privKeyPEM)
    keySpec = PKCS8EncodedKeySpec.new(encoded)
    key_factory.generatePrivate(keySpec)
  end

  def key_factory
    @key_factory ||= KeyFactory.getInstance("RSA")
  end

  def parse_base64(key)
    DatatypeConverter.parseBase64Binary(
      java.lang.String.new(RubyString.string_to_bytes(key), Charset.forName("UTF-8"))
    )
  end

  def replace_private_key_headers(key)
    key = key.gsub("-----BEGIN RSA PRIVATE KEY-----\n",'')
    key = key.gsub('-----END RSA PRIVATE KEY-----','')
  end

  def replace_public_key_headers(key)
    key = key.gsub("-----BEGIN RSA PUBLIC KEY-----\n",'')
    key = key.gsub('-----END RSA PUBLIC KEY-----','')
  end
end
