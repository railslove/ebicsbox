require 'grape-entity'

require_relative './subscriber'

module Box
  module Entities
    class ManagementAccount < Grape::Entity
      expose :name, documentation: { type: "String", desc: "Display name for given bank account" }
      expose :iban, documentation: { type: "String", desc: "Unique bank account IBAN" }
      expose :bic, documentation: { type: "String", desc: "Bank branch's unique BIC" }
      expose :bankname, documentation: { type: "String", desc: "Name of bank account's hosting bank" }
      expose :creditor_identifier, documentation: { type: "String", desc: "Creditor identifier used for direct debits" }

      expose :callback_url, documentation: { type: "String", desc: "URL where webhooks are sent at" }
      expose :url, documentation: { type: "String", desc: "Bank's EBICS server URL" }
      expose :host, documentation: { type: "String", desc: "EBICS Host identifier" }
      expose :partner, documentation: { type: "String", desc: "EBICS partner identifier" }
      expose :statements_format, documentation: { type: "String", desc: "Fetching method for statements (either 'mt940' or 'camt53')"}

      expose(:test_mode, documentation: { type: "Boolean", desc: "Whether this is a test account" }) do |account|
        account.mode == 'File'
      end

      expose :subscribers, using: Entities::Subscriber, if: { type: "full" }

      expose(:_links, documentation: { type: "Hash", desc: "Links to resources" }) do |account, options|
        {
          self: Box.configuration.app_url + "/management/accounts/#{account.iban}",
          subscribers: Box.configuration.app_url + "/management/accounts/#{account.iban}/subscribers",
        }
      end
    end
  end
end
