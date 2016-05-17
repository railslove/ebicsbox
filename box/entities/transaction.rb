require 'grape-entity'

module Epics
  module Box
    module Entities
      class Transaction < Grape::Entity
        expose(:account) { |statement| statement.account.iban }
        expose :eref
        expose :type
        expose :status
        expose :order_type
        expose :ebics_transaction_id
        expose(:_links, documentation: { type: "Hash", desc: "Links to resources" }) do |trx|
          iban = trx.account.iban
          {
            self: Epics::Box.configuration.app_url + "/#{iban}/transactions/#{trx.id}",
            account: Epics::Box.configuration.app_url + "/#{iban}/",
            statements: Epics::Box.configuration.app_url + "/#{iban}/statements?transaction_id=#{trx.id}",
          }
        end
      end
    end
  end
end
