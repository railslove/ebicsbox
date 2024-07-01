# frozen_string_literal: true

require "grape-entity"

require_relative "ebics_user"

module Box
  module Entities
    class Account < Grape::Entity
      expose :name, documentation: {type: "String", desc: "Display name for given bank account"}
      expose :iban, documentation: {type: "String", desc: "Unique bank account IBAN"}
      expose :bic, documentation: {type: "String", desc: "Bank branch's unique BIC"}
      expose :bankname, documentation: {type: "String", desc: "Name of bank account's hosting bank"}
      expose :creditor_identifier, documentation: {type: "String", desc: "Creditor identifier used for direct debits"}
      expose :balance_date, documentation: {type: "Date", desc: "Date of balance"}
      expose :balance_in_cents, documentation: {type: "Integer", desc: "Account balance"}

      expose(:test_mode, documentation: {type: "Boolean", desc: "Whether this is a test account"}) do |account|
        account.mode == "File" || account.mode == "Fake"
      end

      expose(:ebics_user, if: ->(_account, options) { options[:include].try(:include?, "ebics_user") }) do |account|
        ebics_user = account.ebics_user_for(options[:env]["box.user"].id)
        if ebics_user
          Entities::EbicsUser.represent(ebics_user, only: %i[ebics_user signature_class state submitted_at activated_at])
        end
      end

      expose(:_links, documentation: {type: "Hash", desc: "Links to resources"}) do |account, _options|
        {
          self: Box.configuration.app_url + "/#{account.iban}",
          credit: Box.configuration.app_url + "/#{account.iban}/credits",
          debit: Box.configuration.app_url + "/#{account.iban}/debits",
          statements: Box.configuration.app_url + "/#{account.iban}/statements",
          transactions: Box.configuration.app_url + "/#{account.iban}/transactions"
        }
      end
    end
  end
end
