require 'sequel'

require_relative '../init'
require_relative '../queue'
require_relative '../adapters/fake'
require_relative '../adapters/file'
require_relative '../models/event'

module Box
  class Subscriber < Sequel::Model
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
        subscriber_id: id,
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
      Box.configuration.db_passphrase
    end

    def client
      @client ||= client_adapter.new(encryption_keys, passphrase, account.url, account.host, remote_user_id, account.partner)
    end

    def client_adapter
      Adapters.const_get(account.mode)
    rescue => e
      Box.configuration.ebics_client
    end

    def setup!(reset = false)
      fail(AlreadyActivated) if !ini_letter.nil? && !reset
      fail(IncompleteEbicsData) unless ebics_data?
      # TODO: handle exceptions
      Box.logger.info("setting up EBICS keys for subscriber #{id}")
      epics = client_adapter.setup(passphrase, account.url, account.host, remote_user_id, account.partner)
      self.encryption_keys = epics.send(:dump_keys)
      self.save
      Box.logger.info("starting EBICS key exchange for subscriber #{id}")
      epics.INI
      epics.HIA
      self.ini_letter = epics.ini_letter(account.bankname)
      Box.logger.info("EBICS key exchange done and ini letter generated for subscriber #{id}")
      self.submitted_at = DateTime.now
      self.save
      Queue.check_subscriber_activation(id)
    rescue Epics::Error::TechnicalError, Epics::Error::BusinessError => ex
      Box.logger.error("Failed to init subscriber #{id}. Reason='#{ex.message}'")
      false
    end

    def activate!
      Box.logger.info("activating account #{self.id}")
      self.client.HPB
      self.encryption_keys = self.client.send(:dump_keys)
      self.activated_at ||= Time.now
      self.save
      Event.subscriber_activated(self)
      true
    rescue => e
      # TODO: show the error to the user
      Box.logger.error("failed to activate account #{self.id}: #{e.to_s}")
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
  end
end
