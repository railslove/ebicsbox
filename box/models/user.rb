# frozen_string_literal: true

require "sequel"

module Box
  class User < Sequel::Model
    self.raise_on_save_failure = true
    unrestrict_primary_key

    many_to_one :organization
    one_to_many :ebics_users

    def before_create
      super
      self.access_token ||= SecureRandom.hex(32) unless access_token.present?
    end

    def self.find_by_access_token(access_token)
      return unless access_token

      first(access_token: access_token)
    end
  end
end
