require 'grape-entity'
require_relative './transaction'

module Box
  module Entities
    module V2
      class Account < Grape::Entity
        expose :name, documentation: { type: "String", desc: "Name appearing on customer statements" }
        expose :descriptor, documentation: { type: "String", desc: "Internal descriptor" }
        expose :iban
        expose :bic
        expose :balance_date
        expose :balance_in_cents
        expose :creditor_identifier

        expose :ebics_users, using: Entities::EbicsUser
        expose(:url)
        expose(:partner)
        expose(:host)
        expose(:status)

        expose(:callback_url)

        expose(:_links) do |account, options|
          {
            self: Box.configuration.app_url + "/accounts/#{account.iban}",
            transactions: Box.configuration.app_url + "/transactions?iban=#{account.iban}",
            ini_letter: Box.configuration.app_url + "/accounts/#{account.iban}/ini_letter",
          }
        end
      end
    end
  end
end
