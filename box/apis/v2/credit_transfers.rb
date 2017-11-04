require 'grape'

require_relative './api_endpoint'
require_relative '../../entities/v2/credit_transfer'
require_relative '../../validations/unique_transaction_eref'
require_relative '../../validations/length'
require_relative '../../errors/business_process_failure'


module Box
  module Apis
    module V2
      class CreditTransfers < Grape::API
        include ApiEndpoint

        resource :credit_transfers do
          rescue_from Box::BusinessProcessFailure do |e|
            error!({ message: 'Failed to initiate credit transfer.', errors: e.errors }, 400)
          end

          rescue_from Sequel::NoMatchingRow do |e|
            error!({ message: 'Your organization does not have a credit transfer with given id!' }, 404)
          end

          ###
          ### GET /credit_transfers
          ###

          desc "Fetch a list of credit transfers",
            is_array: true,
            headers: AUTH_HEADERS,
            success: Entities::V2::CreditTransfer,
            failure: DEFAULT_ERROR_RESPONSES

          params do
            optional :iban, type: Array[String], desc: "IBAN of an account", coerce_with: ->(value) { value.split(',') }
            optional :page, type: Integer, desc: "page through the results", default: 1
            optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
          end
          get do
            query = Box::Transaction.by_organization(current_organization).credit_transfers.filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::CreditTransfer
          end


          ###
          ### POST /credit_transfers
          ###

          desc "Create a credit transfer",
            headers: AUTH_HEADERS,
            success: Message,
            body_name: 'body',
            failure: DEFAULT_ERROR_RESPONSES,
            detail: <<-USAGE.strip_heredoc
              Creating a credit by parameter should be the preferred way for low-volume transactions
              esp. for use cases where the PAIN XML isn't generated before.

              Once validated, transactions are transmitted asynchronously to the banking system. Errors
              that happen eventually are delivered via Webhooks.
            USAGE

          params do
            requires :account, type: String, desc: "the account to use", documentation: { param_type: 'body' }
            requires :name, type: String, desc: "the customers name"
            optional :bic , type: String, desc: "the customers bic", allow_blank: false
            requires :iban, type: String, desc: "the customers iban"
            requires :amount_in_cents, type: Integer, desc: "amount to credit (charged in cents)", values: 1..1200000000
            requires :end_to_end_reference, type: String, desc: "unique end to end reference", unique_transaction_eref: true
            optional :reference, type: String, length: 140, desc: "description of the transaction (max. 140 char)"
            optional :execution_date, type: Date, desc: "requested execution date", default: -> { Date.today }
            optional :urgent, type: Boolean, desc: "requested execution date", default: false
          end

          post do
            account = current_organization.find_account!(params[:account])
            Credit.v2_create!(current_user, account, declared(params))
            { message: 'Credit transfer has been initiated successfully!' }
          end


          ###
          ### GET /credit_transfers/:id
          ###

          desc "Fetch a credit transfer",
            headers: AUTH_HEADERS,
            success: Entities::V2::CreditTransfer,
            failure: DEFAULT_ERROR_RESPONSES

          get ":id" do
            if params[:id].to_s.match(/([a-f\d]{8}(-[a-f\d]{4}){3}-[a-f\d]{12}?)/i)
              credit_transfer = Box::Transaction.by_organization(current_organization).credit_transfers.first!(public_id: params[:id])
              present credit_transfer, with: Entities::V2::CreditTransfer
            else
              fail Sequel::NoMatchingRow
            end
          end

        end
      end
    end
  end
end
