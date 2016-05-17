require 'grape-entity'

require_relative './subscriber'

module Epics
  module Box
    module Entities
      class Account < Grape::Entity
        expose :name, documentation: { type: "String", desc: "Display name for given bank account" }
        expose :iban, documentation: { type: "String", desc: "Unique bank account IBAN" }
        expose :bic, documentation: { type: "String", desc: "Bank branch's unique BIC" }
        expose :bankname, documentation: { type: "String", desc: "Name of bank account's hosting bank" }
        expose :creditor_identifier, documentation: { type: "String", desc: "Creditor identifier used for direct debits" }
        expose :balance_date, documentation: { type: "Date", desc: "Date of balance" }
        expose :balance_in_cents, documentation: { type: "Integer", desc: "Account balance" }

        expose(:test_mode, documentation: { type: "Boolean", desc: "Whether this is a test account" }) do |account|
          account.mode == 'File' || account.mode == 'Fake'
        end

        expose(:subscriber, if: -> (account, options) { options[:include].try(:include?, 'subscriber') }) do |account|
          if subscriber = account.subscriber_for(options[:env]['box.user'].id)
            Entities::Subscriber.represent(subscriber, only: [:ebics_user, :signature_class, :state, :submitted_at, :activated_at])
          end
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
