# frozen_string_literal: true

require "grape-entity"

module Box
  module Entities
    class EbicsUser < Grape::Entity
      expose(:accounts, documentation: {type: "Array", desc: "Associated IBANs"}) do |ebics_user|
        ebics_user.accounts.map(&:iban)
      end
      expose :id, documentation: {type: "Integer", desc: "Internal id"}
      expose :user_id, documentation: {type: "String", desc: "Associated user id"}
      expose :remote_user_id, as: "ebics_user", documentation: {type: "String", desc: "EBICS user identifier"}
      expose :signature_class, documentation: {type: "String", desc: "EBICS signature class"}
      expose :state, documentation: {type: "String", desc: "Current ebics_user state"}
      expose :submitted_at, documentation: {type: "String", desc: "Date and time when EBICS keys were submitted to bank server"}
      expose :activated_at, documentation: {type: "DateTime", desc: "Date and time when EBICS credentials have been activated"}

      expose(:_links, documentation: {type: "Hash", desc: "Links to resources"}) do |ebics_user, _options|
        {
          self: Box.configuration.app_url + "/management/accounts/#{ebics_user.first_account.iban}/ebics_users/#{ebics_user.id}",
          ini_letter: Box.configuration.app_url + "/management/accounts/#{ebics_user.first_account.iban}/#{ebics_user.id}/ini_letter",
          account: Box.configuration.app_url + "/management/accounts/#{ebics_user.first_account.iban}",
          user: Box.configuration.app_url + "/management/users/#{ebics_user.user.try(:id)}"
        }
      end
    end
  end
end
