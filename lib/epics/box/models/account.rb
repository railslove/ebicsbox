require 'securerandom'
class Epics::Box::Account < Sequel::Model

  AlreadyActivated = Class.new(StandardError)
  IncompleteEbicsData = Class.new(StandardError)

  self.raise_on_save_failure = true

  one_to_many :statements
  one_to_many :transactions

  def self.all_ids
    select(:id).all.map(&:id)
  end

  def passphrase
    Epics::Box.configuration.db_passphrase
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

  def last_imported_at
    DB[:imports].where(account_id: id).order(:date).last.try(:[], :date)
  end

  def imported_at!(date)
    DB[:imports].insert(date: date, account_id: id)
  end

  def active?
    !self.activated_at.nil?
  end

  def ebics_data?
    [user, url, partner, host].all?(&:present?)
  end

  def state
    if active?
      'active'
    elsif ebics_data?
      'ready_to_submit'
    else
      'needs_ebics_data'
    end
  end

  def setup!(reset = false)
    fail(AlreadyActivated) if !ini_letter.nil? && !reset
    fail(IncompleteEbicsData) unless ebics_data?
    # TODO: handle exceptions
    Epics::Box.logger.info("setting up EBICS keys for account #{self.id}")
    epics = client_adapter.setup(self.passphrase, self.url, self.host, self.user, self.partner)
    self.key = epics.send(:dump_keys)
    self.save
    Epics::Box.logger.info("starting EBICS key exchange for account #{self.id}")
    epics.INI
    epics.HIA
    self.ini_letter = epics.ini_letter(self.bankname)
    Epics::Box.logger.info("EBICS key exchange done and ini letter generated for account #{self.id}")
    self.submitted_at = DateTime.now
    self.save
  end

  def activate!
    Epics::Box.logger.info("activating account #{self.id}")
    self.client.HPB
    self.key = self.client.send(:dump_keys)
    self.activated_at = Time.now
    self.save
  rescue Epics::Error => e
    # TODO: show the error to the user
    Epics::Box.logger.error("failed to activate account #{self.id}: #{e.to_s}")
    return false
  end

  class File
    def initialize(*args); end

    def self.setup(*args)
      return new(*args)
    end
    def dump_keys
      "{}"
    end
    def ini_letter(name)
      "ini"
    end
    def INI;end
    def HIA;end
    def HPB;end
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
