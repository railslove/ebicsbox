class Epics::Box::Account < Sequel::Model

  one_to_many :statements
  one_to_many :transactions

  def client
    @client ||= Epics::Client.new(key, passphrase, url, host, user, partner)
  end

  def pain_attributes_hash
    [:name, :bic, :iban, :creditor_identifier].inject({}) {|n, v| n[v]=public_send(v);n }
  end

end
