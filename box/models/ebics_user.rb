# frozen_string_literal: true

require "epics"
require "sequel"

require_relative "../adapters/fake"
require_relative "../adapters/file"
require_relative "../models/event"
require_relative "../queue"

module Box
  class EbicsUser < Sequel::Model
    self.raise_on_save_failure = true

    IncompleteEbicsData = Class.new(StandardError)

    many_to_many :accounts
    many_to_one :user

    def as_event_payload
      {
        account_id: first_account.id,
        user_id: user.id,
        ebics_user: remote_user_id,
        ebics_user_id: id,
        signature_class: signature_class
      }
    end

    def active?
      !!activated_at
    end

    def ebics_data?
      [remote_user_id, first_account.url, first_account.partner, first_account.host].all?(&:present?)
    end

    def passphrase
      Box.configuration.db_passphrase
    end

    def client
      account = first_account
      @client ||= account.client_adapter.new(encryption_keys, passphrase, account.url, account.host, remote_user_id, partner)
    end

    def setup!(account, reset = false)
      return true if !ini_letter.nil? && !reset

      raise(IncompleteEbicsData) unless ebics_data?

      # TODO: handle exceptions
      Box.logger.info("setting up EBICS keys for ebics_user #{id}")
      epics = account.client_adapter.setup(passphrase, account.url, account.host, remote_user_id, account.partner)
      self.encryption_keys = epics.send(:dump_keys)
      save

      Box.logger.info("starting EBICS key exchange for ebics_user #{id}")
      epics.INI
      epics.HIA
      self.ini_letter = epics.ini_letter(account.bankname)
      Box.logger.info("EBICS key exchange done and ini letter generated for ebics_user #{id}")
      self.submitted_at = Time.now

      save
    rescue Epics::Error::TechnicalError, Epics::Error::BusinessError => ex
      Box.logger.error("Failed to init ebics_user #{id}. Reason='#{ex.message}'")
      false
    end

    def activate!
      Box.logger.info("activating account #{id}")
      client.HPB

      self.encryption_keys = client.send(:dump_keys)
      self.activated_at ||= Time.now
      save
      Box::Event.ebics_user_activated(self)
      true
    rescue => e
      # TODO: show the error to the user
      Box.logger.error("failed to activate account #{id}: #{e}")
      false
    end

    def refresh_bank_keys!
      Box.logger.info("Refresh bank keys for account #{id}")
      client.HPB

      self.encryption_keys = client.send(:dump_keys)
      save
      true
    rescue => e
      # TODO: show the error to the user
      Box.logger.error("Failed to refresh bank keys for account #{id}: #{e}")
      false
    end

    def state
      if active?
        "active"
      elsif submitted_at.present?
        "submitted"
      elsif ebics_data?
        "ready_to_submit"
      else
        "needs_ebics_data"
      end
    end

    def first_account
      accounts.first
    end
  end
end
