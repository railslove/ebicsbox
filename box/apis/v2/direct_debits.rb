require 'grape'

require_relative './api_endpoint'
require_relative '../../entities/v2/direct_debit'
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
            optional :iban, type: String, desc: 'IBAN of an account'
            optional :page, type: Integer, desc: 'page through the results', default: 1
            optional :per_page, type: Integer, desc: 'how many results per page', values: 1..100, default: 25
          end
          get do
            query = Box::Transaction.by_organization(current_organization).direct_debits.filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::DirectDebit
          end

          ###
          ### POST /direct_debits
          ###

          params do
            requires :account, type: String, desc: 'YOURACCOUNTIBAN'
            requires :name, type: String, desc: 'the recipient name'
            requires :iban, type: String, desc: 'the recipient iban'
            requires :bic, type: String, desc: 'recipient bic'
            requires :amount_in_cents, type: Integer, desc: "amount to debit in cents", values: 1..1200000000
            requires :reference, type: String, length: 140, desc: "Message for your customer's statement"
            requires :end_to_end_reference, type: String, desc: "unique id", unique_transaction_eref: true
            requires :mandate_id, type: String, desc: "unique id presented to customer" # max 35 digits
            requires :mandate_signature_date, type: Date, desc: "2016-05-01"
          end
          post do
            account = current_organization.find_account!(params[:account])
            DirectDebit.v2_create!(account, declared(params), current_user)
            { message: 'Direct debit has been initiated successfully!' }
          end

          # ###
          # ### GET /direct_debits/:id
          # ###

          get ":id" do
            if params[:id].to_s.match(/([a-f\d]{8}(-[a-f\d]{4}){3}-[a-f\d]{12}?)/i)
              direct_debits = Box::Transaction.by_organization(current_organization).direct_debits.first!(public_id: params[:id])
              present direct_debits, with: Entities::V2::DirectDebit
            else
              fail Sequel::NoMatchingRow
            end
          end
        end
      end
    end
  end
end
