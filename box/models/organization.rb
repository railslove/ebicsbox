require 'securerandom'
require 'sequel'

require_relative '../init'
require_relative './account'

module Box
  class Organization < Sequel::Model
    self.raise_on_save_failure = true

    one_to_many :accounts
    one_to_many :users

    def self.find_by_management_token(token)
      return unless token
      first(management_token: token)
    end

    def self.register(params)
      orga = new(params)
      orga.management_token ||= SecureRandom.hex
      orga.save
    end

    def find_account!(iban)
      accounts_dataset.first!(iban: iban)
    rescue Sequel::NoMatchingRow => ex
      fail Account::NotFound.for_orga(organization_id: self.id, iban: iban)
    end
  end
end
