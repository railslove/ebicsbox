# frozen_string_literal: true

require 'grape-entity'
require_relative './transaction'

module Box
  module Entities
    module V2
      class CreditTransfer < Grape::Entity
        expose(:public_id, as: 'id')
        expose(:account) { |transaction| transaction.account.iban }
        expose(:name)
        expose(:iban)
        expose(:bic)
        expose(:amount, as: 'amount_in_cents')
        expose(:currency)
        expose(:eref, as: 'end_to_end_reference')
        expose(:ebics_order_id)
        expose(:ebics_transaction_id)
        expose(:reference)
        expose(:executed_on)
        expose(:status)
        expose(:_links) do |transaction|
          iban = transaction.account.iban
          {
            self: Box.configuration.app_url + "/credit_transfers/#{transaction.public_id}",
            account: Box.configuration.app_url + "/accounts/#{iban}/"
          }
        end

        def name
          object.metadata.fetch('name') do
            object.parsed_payload[:payments].first[:transactions].first[:name]
          end
        end

        def iban
          object.metadata.fetch('iban') do
            object.parsed_payload[:payments].first[:transactions].first[:iban]
          end
        end

        def bic
          object.metadata.fetch('bic') do
            object.parsed_payload[:payments].first[:transactions].first[:bic]
          end
        end

        def reference
          object.metadata.fetch('reference') do
            object.parsed_payload[:payments].first[:transactions].first[:remittance_information]
          end
        end

        def executed_on
          object.metadata.fetch('execution_date') do
            object.parsed_payload[:payments].first[:execution_date]
          end
        end
      end
    end
  end
end
