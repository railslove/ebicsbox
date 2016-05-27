require 'grape'

require_relative './api_endpoint'
require_relative '../../entities/v2/credit_transfer'

module Box
  module Apis
    module V2
      class CreditTransfers < Grape::API
        include ApiEndpoint

        resource :credit_transfers do

          ###
          ### GET /credit_transfers
          ###

          params do
            optional :iban, type: Array[String], desc: "IBAN of an account", coerce_with: ->(value) { value.split(',') }
            optional :page, type: Integer, desc: "page through the results", default: 1
            optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
            optional :from, type: Date, desc: "Date from which on to filter the results"
            optional :to, type: Date, desc: "Date to which filter results"
          end
          get do
            query = Box::Transaction.by_organization(current_organization).credit_transfers.filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::CreditTransfer
          end


          ###
          ### POST /credit_transfers
          ###

          params do
            requires :account, type: String, desc: "the account to use"
            requires :name, type: String, desc: "the customers name"
            requires :bic , type: String, desc: "the customers bic"
            requires :iban, type: String, desc: "the customers iban"
            requires :amount_in_cents, type: Integer, desc: "amount to credit (charged in cents)", values: 1..12000000
            requires :end_to_end_reference, type: String, desc: "unique end to end reference to ", unique_transaction: true

            optional :reference, type: String, desc: "description of the transaction (max. 140 char)"
            optional :execution_date, type: Date, desc: "requested execution date"
            optional :urgent, type: Boolean, desc: "requested execution date", default: false
          end
          post do
            "create"
          end


          ###
          ### GET /credit_transfers/:id
          ###

          get ":id" do
            credit_transfer = Box::Transaction.by_organization(current_organization).credit_transfers.find(id: params[:id])
            present credit_transfer, with: Entities::V2::CreditTransfer
          end

        end
      end
    end
  end
end
