require 'grape-entity'

module Epics
  module Box
    module Entities
      class Account < Grape::Entity
        expose :name
        expose :bic
        expose :iban
        expose :creditor_identifier
        expose :bankname
        expose :activated_at

        expose :test_mode do |account|
          account.mode == 'File'
        end

        expose :_links do |account, options|
          {
            self: Epics::Box.configuration.app_url + "/accounts/#{account.iban}",
            credit: Epics::Box.configuration.app_url + "/accounts/#{account.iban}/credits",
            debit: Epics::Box.configuration.app_url + "/accounts/#{account.iban}/debits",
            statements: Epics::Box.configuration.app_url + "/accounts/#{account.iban}/statements",
            transactions: Epics::Box.configuration.app_url + "/accounts/#{account.iban}/transactions",
          }
        end
      end
    end
  end
end
