# frozen_string_literal: true

require "grape-entity"
require_relative "./transaction"

module Box
  module Entities
    module V2
      class DirectDebit < Grape::Entity
        expose(:public_id, as: "id")
        expose(:account) { |transaction| transaction.account.iban }
        expose(:name)
        expose(:iban)
        expose(:bic)
        expose(:amount, as: "amount_in_cents")
        expose(:eref, as: "end_to_end_reference")
        expose(:ebics_order_id)
        expose(:ebics_transaction_id)
        expose(:reference)
        expose(:collection_date)
        expose(:status)
        expose(:_links) do |transaction|
          iban = transaction.account.iban
          {
            self: Box.configuration.app_url + "/direct_debits/#{transaction.id}",
            account: Box.configuration.app_url + "/accounts/#{iban}/"
          }
        end

        def name
          first_transaction.name
        end

        def iban
          first_transaction.iban
        end

        def bic
          first_transaction.bic
        end

        def reference
          first_transaction.remittance_information
        end

        def collection_date
          payments.first[:collection_date]
        end

        private

        def first_transaction
          OpenStruct.new(payments.first[:transactions]&.first)
        end

        def payments
          object.parsed_payload.fetch(:payments, [])
        end
      end
    end
  end
end
