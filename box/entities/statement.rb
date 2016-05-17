require 'grape-entity'
require_relative './transaction'

module Epics
  module Box
    module Entities
      class Statement < Grape::Entity
        expose :public_id, as: "id"
        expose(:account) { |statement| statement.account.iban }
        expose :name
        expose :bic
        expose :iban
        expose :type
        expose :amount, documentation: { type: "Integer", desc: "Amount in cents" }
        expose :date
        expose(:remittance_information, documentation: { type: "String", desc: "Wire transfer reference" }) { |statement| statement[:svwz] || statement[:information] }
        expose :eref, documentation: { type: "String", desc: "SEPA end-to-end reference" }
        expose :mref, documentation: { type: "String", desc: "SEPA mandate reference" }
        expose :reference, documentation: { type: "String", desc: "Additional references (like customer reference, etc.)" }
        expose :bank_reference
        expose :creditor_identifier, documentation: { type: "String", desc: "SEPA creditor identifier" }
        expose :swift_code, as: :transaction_type, documentation: { type: "String", desc: "SWIFT transaction code" }
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
