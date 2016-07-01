require 'grape-entity'
require_relative './transaction'

module Box
  module Entities
    module V2
      class DirectDebit < Grape::Entity
        expose(:account) { |transaction| transaction.account.iban }
        expose(:bic) { |transaction| transaction.account.bic }
        expose(:amount, as: 'amount_in_cents')
        expose(:status)
      end
    end
  end
end
