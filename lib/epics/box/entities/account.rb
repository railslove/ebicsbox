require 'grape-entity'

module Epics
  module Box
    module Entities
      class Account < Grape::Entity
        expose :name, documentation: { type: "String", desc: "Display name for given bank account" }
        expose :iban, documentation: { type: "String", desc: "Unique bank account IBAN" }
        expose :bic, documentation: { type: "String", desc: "Bank branch's unique BIC" }
        expose :bankname, documentation: { type: "String", desc: "Name of bank account's hosting bank" }
        expose :creditor_identifier, documentation: { type: "String", desc: "Creditor identifier used for direct debits" }
        expose :activated_at, documentation: { type: "DateTime", desc: "Date and time when ebics client credentials were activated" }

        expose(:test_mode, documentation: { type: "Boolean", desc: "Whether this is a test account" }) do |account|
          account.mode == 'File'
        end

        expose(:_links, documentation: { type: "Hash", desc: "Links to resources" }) do |account, options|
          {
            self: Epics::Box.configuration.app_url + "/#{account.iban}",
            credit: Epics::Box.configuration.app_url + "/#{account.iban}/credits",
            debit: Epics::Box.configuration.app_url + "/#{account.iban}/debits",
            statements: Epics::Box.configuration.app_url + "/#{account.iban}/statements",
            transactions: Epics::Box.configuration.app_url + "/#{account.iban}/transactions",
          }
        end
      end
    end
  end
end
