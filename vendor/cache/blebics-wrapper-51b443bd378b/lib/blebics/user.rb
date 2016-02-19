class Blebics::User
  java_implements 'de.businesslogics.ebics.client.EbicsUser'
  java_signature 'byte[]  authenticate(byte[] digest)'
  java_signature 'byte[]  decrypt(byte[] encryptedKey)'
  java_signature 'RSAPublicKey  getEncrPubKey()'
  java_signature 'EbicsPartner  getPartner()'
  java_signature 'String  getPartnerID()'
  java_signature 'String getSecurityMedium()'
  java_signature 'SignatureVersion getSignatureVersion()'
  java_signature 'byte[] sign(byte[] digest, String filename, Date fileDate, String orderType)'

  attr_accessor :user_id, :partner, :client
  def initialize(partner, user_id, client)
    self.partner  = partner
    self.user_id  = user_id
    self.client   = client
  end

  def authenticate(digest)
    x002 = client.x
    x002.authenticate(digest)
  end

  def decrypt(encrypted_key)
    e002 = client.e
    e002.decrypt(encrypted_key)
  end

  def get_encr_pub_key
    e002 = client.e
    e002.get_public_key()
  end

  def get_security_medium()
    String.new("0000")
  end

  def get_partner
    partner
  end

  def get_partner_id
    partner.get_partner_id
  end

  def get_signature_version
    SignatureVersion::A006
  end

  def sign(digest, filename, fileDate, orderType)
    a006 = client.a
    a006.sign(digest, RubyString.string_to_bytes(OpenSSL::Random.random_bytes(32)))
  end
end

