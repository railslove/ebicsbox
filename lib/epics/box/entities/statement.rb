require 'grape-entity'
require 'epics/box/presenters/transaction_presenter'

module Epics
  module Box
    module Entities
      class Statement < Grape::Entity
        expose(:account) { |statement| statement.account.iban }
        expose :name
        expose :bic
        expose :iban
        expose :type
        expose :amount
        expose :date
        expose(:remittance_information) { |statement| statement[:svwz] || statement[:information] }
        expose :eref
        expose :mref
        expose :reference
        expose :bank_reference
        expose :creditor_identifier
        expose :swift_code, as: :transaction_type
        expose(:_links, documentation: { type: "Hash", desc: "Links to resources" }) do |statement|
          iban = statement.account.iban
          trx = statement.transaction
          {
            self: Epics::Box.configuration.app_url + "/#{iban}/statements/#{statement.id}",
            account: Epics::Box.configuration.app_url + "/#{iban}/",
            transaction: !!trx ? Epics::Box.configuration.app_url + "/#{iban}/transactions/#{trx.id}" : nil,
          }
        end
      end
    end
  end
end
