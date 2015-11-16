class Epics::Box::Subscriber < Sequel::Model
  self.raise_on_save_failure = true

  AlreadyActivated = Class.new(StandardError)
  IncompleteEbicsData = Class.new(StandardError)

  many_to_one :account
  many_to_one :user

  def as_event_payload
    {
      account_id: account.id,
      user_id: user.id,
      subscriber: remote_user_id,
      signature_class: signature_class,
    }
  end

  def active?
    !!activated_at
  end

  def ebics_data?
    [remote_user_id, account.url, account.partner, account.host].all?(&:present?)
  end

  def passphrase
    Epics::Box.configuration.db_passphrase
  end

  def client
    @client ||= client_adapter.new(encryption_keys, passphrase, account.url, account.host, remote_user_id, account.partner)
  end

  def client_adapter
    self.class.const_get(account.mode)
  rescue => e
    Epics::Client
  end

  def setup!(reset = false)
    fail(AlreadyActivated) if !ini_letter.nil? && !reset
    fail(IncompleteEbicsData) unless ebics_data?
    # TODO: handle exceptions
    Epics::Box.logger.info("setting up EBICS keys for account #{self.id}")
    epics = client_adapter.setup(passphrase, account.url, account.host, remote_user_id, account.partner)
    self.encryption_keys = epics.send(:dump_keys)
    self.save
    Epics::Box.logger.info("starting EBICS key exchange for account #{self.id}")
    epics.INI
    epics.HIA
    self.ini_letter = epics.ini_letter(account.bankname)
    Epics::Box.logger.info("EBICS key exchange done and ini letter generated for account #{self.id}")
    self.submitted_at = DateTime.now
    self.save
    Epics::Box::Queue.check_subscriber_activation(id)
  end

  def activate!
    Epics::Box.logger.info("activating account #{self.id}")
    self.client.HPB
    self.encryption_keys = self.client.send(:dump_keys)
    self.activated_at ||= Time.now
    self.save
    Epics::Box::Event.subscriber_activated(self)
    true
  rescue => e
    # TODO: show the error to the user
    Epics::Box.logger.error("failed to activate account #{self.id}: #{e.to_s}")
    false
  end

  def state
    if active?
      'active'
    elsif submitted_at.present?
      'submitted'
    elsif ebics_data?
      'ready_to_submit'
    else
      'needs_ebics_data'
    end
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
