require 'grape-entity'
require_relative './transaction'

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
        expose :amount
        expose :date, as: "executed_on"
        expose(:reference) { |transaction| transaction[:svwz] || transaction[:information] }
        expose :eref, as: 'end_to_end_reference'
        expose(:_links) do |transaction|
          iban = transaction.account.iban
          {
            self: Box.configuration.app_url + "/transactions/#{transaction.id}",
            account: Box.configuration.app_url + "/accounts/#{iban}/",
          }
        end
      end
    end
  end
end
