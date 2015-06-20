class Epics::Box::Account < Sequel::Model
  one_to_many :statements
  one_to_many :transactions

  def self.all_ids
    select(:id).all.map(&:id)
  end

  def client
    @client ||= client_adapter.new(key, passphrase, url, host, user, partner)
  end

  def client_adapter
    self.class.const_get(mode)
  rescue => e
    Epics::Client
  end

  def pain_attributes_hash
    [:name, :bic, :iban, :creditor_identifier].inject({}) {|n, v| n[v]=public_send(v);n }
  end

  def credit_pain_attributes_hash
    [:name, :bic, :iban].inject({}) {|n, v| n[v]=public_send(v);n }
  end

  class File
    def initialize(*args); end

    def STA(from, to)
      ::File.read( ::File.expand_path("~/sta.mt940"))
    end

    def HAC(from, to)
      ::File.open( ::File.expand_path("~/hac.xml"))
    end

    def CD1(pain)
      ["TRX#{SecureRandom.hex(6)}", "N#{SecureRandom.hex(6)}"]
    end
    alias :CDD :CD1
    alias :CDB :CD1
    alias :CCT :CD1
  end
end
