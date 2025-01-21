# frozen_string_literal: true

require "grape-entity"

module Box
  module Entities
    module V2
      class Transaction < Grape::Entity
        expose :public_id, as: "id"
        expose(:account) { |transaction| transaction.account.iban }
        expose :name
        expose :iban
        expose :bic
        expose :type
        expose :expected
        expose :reversal
        expose :amount, as: "amount_in_cents"
        expose :date, as: "executed_on"
        expose(:settled_at) { |trx| trx.settled ? trx.date : nil }
        expose(:reference) { |transaction| transaction[:svwz] || transaction[:information] }
        expose :eref, as: "end_to_end_reference"
        expose(:_links) do |transaction|
          iban = transaction.account.iban
          {
            self: Box.configuration.app_url + "/transactions/#{transaction.public_id}",
            account: Box.configuration.app_url + "/accounts/#{iban}/"
          }
        end
      end
    end
  end
end
