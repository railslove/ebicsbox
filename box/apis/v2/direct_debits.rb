require 'grape'

require_relative './api_endpoint'
require_relative '../../entities/v2/direct_debits'
require_relative '../../validations/unique_transaction_eref'
require_relative '../../validations/length'
require_relative '../../errors/business_process_failure'


module Box
  module Apis
    module V2
      class DirectDebits < Grape::API
        include ApiEndpoint

        resource :direct_debits do
          rescue_from Box::BusinessProcessFailure do |e|
            error!({ message: 'Failed to initiate direct debits.', errors: e.errors }, 400)
          end

          rescue_from Sequel::NoMatchingRow do |e|
            error!({ message: 'Your organization does not have a direct debit with given id!' }, 404)
          end

          ###
          ### GET /direct_debits
          ###

          params do
            optional :iban, type: Array[String], desc: "IBAN of an account", coerce_with: ->(value) { value.split(',') }
            optional :page, type: Integer, desc: "page through the results", default: 1
            optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
          end
          get do
            query = Box::Transaction.by_organization(current_organization).direct_debits.filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::CreditTransfer
          end


          ###
          ### POST /direct_debits
          ###

          params do
            requires :account, type: String, desc: "the account to use"
            requires :name, type: String, desc: "the customers name"
            requires :iban, type: String, desc: "the customers iban"
            requires :amount_in_cents, type: Integer, desc: "amount to debit (charged in cents)", values: 1..1200000000
            requires :end_to_end_reference, type: String, desc: "unique end to end reference", unique_transaction_eref: true
            optional :bic , type: String, desc: "the customers bic", allow_blank: false
            optional :reference, type: String, length: 140, desc: "description of the transaction (max. 140 char)"
            optional :execution_date, type: Date, desc: "requested execution date", default: -> { Date.today }
            optional :urgent, type: Boolean, desc: "requested execution date", default: false
          end
          post do
            account = current_organization.find_account!(params[:account])
            DirectDebit.create!(account, declared(params), current_user)
            { message: 'Direct debit has been initiated successfully!' }
          end


          ###
          ### GET /direct_debits/:id
          ###

          get ":iban" do
            if params[:iban].to_s.match(/([a-f\d]{8}(-[a-f\d]{4}){3}-[a-f\d]{12}?)/i)
              direct_debits = Box::Transaction.by_organization(current_organization).direct_debits.first!(public_id: params[:iban])
              present direct_debits, with: Entities::V2::DirectDebits
            else
              fail Sequel::NoMatchingRow
            end
          end

        end
      end
    end
  end
end
