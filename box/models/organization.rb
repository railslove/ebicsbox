# frozen_string_literal: true

require 'sequel'
require 'securerandom'

require_relative './account'

module Box
  class Organization < Sequel::Model
    self.raise_on_save_failure = true
    unrestrict_primary_key

    one_to_many :accounts
    one_to_many :users

    def self.find_by_management_token(token)
      return unless token

      first(management_token: token)
    end

    def self.register(params)
      orga = new(params)
      orga.webhook_token ||= SecureRandom.hex
      orga.save
    end

    def events
      accounts_dataset.left_join(:events)
    end

    def find_account!(iban)
      accounts_dataset.first!(iban: iban)
    rescue Sequel::NoMatchingRow => _ex
      raise Account::NotFound.for_orga(organization_id: id, iban: iban)
    end
  end
end
