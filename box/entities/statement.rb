# frozen_string_literal: true

require "grape-entity"
require_relative "transaction"

module Box
  module Entities
    class Statement < Grape::Entity
      expose :public_id, as: "id"
      expose(:account) { |statement| statement.account.iban }
      expose :name
      expose :bic
      expose :iban
      expose :type, documentation: {type: "Enum", desc: "Type of statement", values: %w[credit debit] }
      expose :expected, documentation: {type: "Boolean", desc: "Expected statement are not yet confirmed"}
      expose :reversal, documentation: {type: "Boolean", desc: "Reversal of a previous transaction"}
      expose :amount, documentation: {type: "Integer", desc: "Amount in cents"}
      expose :date
      expose(:remittance_information, documentation: {type: "String", desc: "Wire transfer reference"}) { |statement| statement[:svwz] || statement[:information] }
      expose :eref, documentation: {type: "String", desc: "SEPA end-to-end reference"}
      expose :mref, documentation: {type: "String", desc: "SEPA mandate reference"}
      expose :reference, documentation: {type: "String", desc: "Additional references (like customer reference, etc.)"}
      expose :bank_reference
      expose :creditor_identifier, documentation: {type: "String", desc: "SEPA creditor identifier"}
      expose :swift_code, as: :transaction_type, documentation: {type: "String", desc: "SWIFT transaction code"}
      expose :tx_id, as: :transaction_id, documentation: {type: "String", desc: "Transaction ID as given by the bank"}
      expose(:_links, documentation: {type: "Hash", desc: "Links to resources"}) do |statement|
        iban = statement.account.iban
        trx = statement.transaction
        {
          self: Box.configuration.app_url + "/#{iban}/statements/#{statement.id}",
          account: Box.configuration.app_url + "/#{iban}/",
          transaction: (!!trx) ? Box.configuration.app_url + "/#{iban}/transactions/#{trx.id}" : nil
        }
      end
    end
  end
end
