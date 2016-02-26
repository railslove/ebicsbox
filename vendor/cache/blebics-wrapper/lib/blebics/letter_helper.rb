class LetterHelper
  attr_accessor :key

  def initialize(key)
    self.key = key
  end

  def exponent_size
    self.key.get_public_key.get_public_exponent.size * 8
  end

  def exponent_string
    self.key.get_public_key.get_public_exponent.to_s(16)
  end

  def modulus_size
    self.key.get_public_key.get_modulus.size * 8
  end

  def modulus_string
    self.key.get_public_key.get_modulus.to_s(16)
  end

  def sha256
    c = [ exponent_string.gsub(/^0*/,''), modulus_string.gsub(/^0*/,'') ].map(&:downcase).join(" ")
    OpenSSL::Digest::SHA256.new.digest(c).strip.unpack("H*").join.upcase
  end

  def pretty_format(meth)
    public_send(meth).upcase.scan(/.{2}/).join(" ")
  end

end
