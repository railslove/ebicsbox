java_import "org.jruby.RubyString"

class Blebics::PasswordCallback
  java_implements 'de.businesslogics.zkasecurity.PasswordCallback'
  java_signature 'char[] getPassword()'

  attr_accessor :passphrase

  def initialize(passphrase)
    self.passphrase = passphrase
  end

  def getPassword()
    RubyString.string_to_bytes(self.passphrase)
  end
end
