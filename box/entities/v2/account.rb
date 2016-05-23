require 'grape-entity'
require_relative './transaction'

module Box
  module Entities
    module V2
      class Account < Grape::Entity
        expose :name, documentation: { type: "String", desc: "Internal display name for given account" }
        # expose :addressor, documentation: { type: "String", desc: "Name appearing on customer statements" }
        expose :iban
        expose :bic
        expose :balance_date
        expose :balance_in_cents
        expose :creditor_identifier

        # expose(:bank) do |account|
        #   expose :name
        #   expose :full_name
        #   expose :city
        #   expose :postal_code
        #   expose :bank_identifier
        # end

        expose(:subscriber) { |account| account.subscribers.first&.remote_user_id }
        expose(:url)
        expose(:partner)
        expose(:host)
        expose(:status)

        expose(:callback_url)

        expose(:_links) do |account, options|
          {
            self: Box.configuration.app_url + "/accounts/#{account.iban}",
            statements: Box.configuration.app_url + "/statements?iban=#{account.iban}",
            transactions: Box.configuration.app_url + "/transactions?iban=#{account.iban}",
          }
        end
      end
    end
  end
end
