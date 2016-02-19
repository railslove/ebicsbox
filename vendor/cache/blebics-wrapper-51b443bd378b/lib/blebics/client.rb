java_import "java.security.spec.KeySpec"
java_import "java.security.spec.PKCS8EncodedKeySpec"
java_import "java.security.spec.X509EncodedKeySpec"
java_import "java.security.KeyFactory"
java_import "java.security.KeyPair"
java_import "javax.crypto.Cipher"
java_import "javax.crypto.SecretKey"
java_import "javax.crypto.SecretKeyFactory"
java_import "javax.crypto.spec.IvParameterSpec"
java_import "javax.crypto.spec.PBEKeySpec"
java_import "javax.crypto.spec.SecretKeySpec"
java_import "javax.xml.bind.DatatypeConverter"
java_import "java.nio.charset.Charset"
java_import "org.jruby.RubyString"
java_import "org.jruby.Ruby"
java_import "org.jruby.javasupport.JavaUtil"

class Blebics::Client
  attr_accessor :passphrase, :url, :host_id, :user_id, :partner_id, :keys, :keys_content
  attr_writer :iban, :bic, :name

  def initialize(keys_content, passphrase, url, host_id, user_id, partner_id)
    self.keys_content = keys_content.respond_to?(:read) ? keys_content.read : keys_content if keys_content
    self.passphrase = passphrase
    self.keys = extract_keys if keys_content
    self.url  = url
    self.host_id    = host_id
    self.user_id    = user_id
    self.partner_id = partner_id
  end

  def inspect
    "#<#{self.class}:#{self.object_id}
     @keys=#{self.keys.keys},
     @user_id=\"#{self.user_id}\",
     @partner_id=\"#{self.partner_id}\""
  end

  def bank
    @bank ||= EbicsBankImpl.new(host_id, URL.new(url), EncryptionVersion::E002, nil, AuthenticationVersion::X002, nil)
  end

  def partner
    @partner ||= EbicsPartnerImpl.new(bank, partner_id)
  end

  def user
    @user ||= Blebics::User.new(partner, user_id, self)
  end

  def session
    @session ||= begin
      session = EbicsSession.new(user)
      session.setProtocolVersion(ProtocolVersion::H004)
      session
    end
  end

  def key_management
    @key_management ||= KeyManagement.new(session)
  end

  def e
    @e ||= begin
      key_pair = Blebics::PemConverter.new(keys["E002"]).key_pair
      E002PrivateKey.new(
        self.user_id,
        key_pair
      )
    end
  end

  def a
    @a ||= begin
      key_pair = Blebics::PemConverter.new(keys["A006"]).key_pair
      A006PrivateKey.new(
        key_pair
      )
    end
  end

  def x
    @x ||= begin
      key_pair = Blebics::PemConverter.new(keys["X002"]).key_pair
      X002PrivateKey.new(
        self.user_id,
        key_pair
      )
    end
  end

  def bank_e
    @bank_e ||= begin
      public_key = Blebics::PemConverter.new(keys["#{host_id.upcase}.E002"]).public_key
      E002PublicKey.new(
        self.user_id,
        public_key
      )
    end
  end

  def bank_x
    @bank_x ||= begin
      public_key = Blebics::PemConverter.new(keys["#{host_id.upcase}.X002"]).public_key
      X002PublicKey.new(
        self.user_id,
        public_key
      )
    end
  end

  def name
    @name ||= (self.HTD; @name)
  end

  def iban
    @iban ||= (self.HTD; @iban)
  end

  def bic
    @bic ||= (self.HTD; @bic)
  end

  def self.setup(passphrase, url, host_id, user_id, partner_id, keysize = 2048)
    client = new(nil, passphrase, url, host_id, user_id, partner_id)
    client.keys = %w(A006 X002 E002).each_with_object({}) do |type, memo|
      memo[type] = OpenSSL::PKey::RSA.generate(keysize).to_pem
    end
    client
  end

  def ini_letter(bankname)
    raw = File.read(File.join(File.dirname(__FILE__), '../letter/', 'ini.erb'))
    ERB.new(raw).result(binding)
  end

  def save_ini_letter(bankname, path)
    File.write(path, ini_letter(bankname))
    path
  end

  def credit(document)
    self.CCT(document)
  end

  def debit(document, type = :CDD)
    self.public_send(type, document)
  end

  def statements(from = nil, to = nil, type = :STA)
    self.public_send(type, from, to)
  end

  def HIA
    key_management.sendHIA(e.get_public_key, nil, x.get_public_key, nil);
  end

  def INI
    key_management.sendINI(SignatureVersion::A006, a.get_public_key, nil)
  end

  def HPB
    Nokogiri::XML(download("HPB")).xpath("//xmlns:PubKeyValue", xmlns: "urn:org:ebics:H004").each do |node|
      type = node.parent.last_element_child.content

      modulus  = Base64.decode64(node.at_xpath(".//*[local-name() = 'Modulus']").content)
      exponent = Base64.decode64(node.at_xpath(".//*[local-name() = 'Exponent']").content)

      bank   = OpenSSL::PKey::RSA.new
      bank.n = OpenSSL::BN.new(modulus, 2)
      bank.e = OpenSSL::BN.new(exponent, 2)

      self.keys["#{host_id.upcase}.#{type}"] = bank.to_pem
    end

    [bank_x, bank_e]
  end

  def CD1(document)
    upload("CD1", document)
  end

  def CDD(document)
    upload("CDD", document)
  end

  def CCT(document)
    upload("CCT", document)
  end

  def STA(from = nil, to = nil)
    download("STA", from, to)
  end

  def C52(from = nil, to = nil)
    download("C52", from, to)
  end

  def C53(from = nil, to = nil)
    download("C53", from, to)
  end

  def HAA
    Nokogiri::XML(download("HAA")).at_xpath("//xmlns:OrderTypes", xmlns: "urn:org:ebics:H004").content.split(/\s/)
  end

  def HTD
    Nokogiri::XML(download("HTD")).tap do |htd|
      @iban ||= htd.at_xpath("//xmlns:AccountNumber[@international='true']", xmlns: "urn:org:ebics:H004").text
      @bic  ||= htd.at_xpath("//xmlns:BankCode[@international='true']", xmlns: "urn:org:ebics:H004").text
      @name ||= htd.at_xpath("//xmlns:Name", xmlns: "urn:org:ebics:H004").text
    end.to_xml
  end

  def HPD
    download("HPD")
  end

  def HKD
    download("HKD")
  end

  def PTK(from = nil, to = nil)
    download("PTK", from, to)
  end

  def HAC(from = nil, to = nil)
    download("HAC", from, to)
  end

  def save_keys(path)
    File.write(path, dump_keys)
  end

  def distributed_signature
    @distributed_signature ||= Blebics::DistributedElectronicSignature.new(self)
  end

  private

  def download(order_type, from = 0, to = Time.now.to_i)
    from = from.to_time.to_i if from.kind_of?(Date)
    to = to.to_time.to_i if to.kind_of?(Date)
    transfer = FileTransfer.new(session)
    output_stream = ByteArrayOutputStream.new
    transfer_state = transfer.fetchFile(
      OrderType.new(order_type),
      from && YYMMDD.new(from),
      to && YYMMDD.new(to),
      output_stream
    )
    output_stream.to_s
  end

  def upload(order_type, document)
    transfer = FileTransfer.new(session)
    document = RubyString.string_to_bytes(document)
    order_id = transfer.sendFile(
      document,
      OrderType.new(order_type),
      [user].to_java(EbicsBusinessUser),
      false
    )
  end

  def extract_keys
    JSON.load(self.keys_content).each_with_object({}) do |(type, key), memo|
      memo[type] = decrypt(key) if key
    end
  end

  def dump_keys
    JSON.dump(keys.each_with_object({}) {|(k,v),m| m[k] = encrypt(v)})
  end

  def cipher
    @cipher ||= Cipher.getInstance("AES/CBC/PKCS5Padding");
  end

  def encrypt(data)
    salt = RubyString.string_to_bytes(OpenSSL::Random.random_bytes(8))
    data = RubyString.string_to_bytes(data)

    setup_cipher(:encrypt, secret(salt), salt)
    result = [
      String.from_java_bytes(salt),
      String.from_java_bytes(cipher.update(data)),
      String.from_java_bytes(cipher.doFinal())
    ].join
    Base64.strict_encode64(result)
  end

  def decrypt(data)
    data = Base64.strict_decode64(data)
    salt = RubyString.string_to_bytes(data[0..7])
    data = RubyString.string_to_bytes(data[8..-1])

    setup_cipher(:decrypt, secret(salt), salt)
    String.from_java_bytes(cipher.doFinal(data))
  end

  def secret(salt)
    factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1")
    passphrase = self.passphrase.to_java(java.lang.String)
    spec = PBEKeySpec.new(passphrase.toCharArray(), salt, 1, 256)
    tmp = factory.generateSecret(spec)
    secret = SecretKeySpec.new(tmp.getEncoded(), "AES")
  end

  def ivspec
    @ivspec ||= begin
      IvParameterSpec.new(iv.getBytes())
    end
  end

  def iv
    # TODO: We need proper IV handling
    ("\0"*16).to_java(java.lang.String)
  end

  def setup_cipher(method, secret, salt)
    mode = method == :encrypt ? Cipher::ENCRYPT_MODE : Cipher::DECRYPT_MODE
    cipher.init(mode, secret, ivspec)
  end

end
