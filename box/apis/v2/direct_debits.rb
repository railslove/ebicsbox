# frozen_string_literal: true

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
            error!({ message: 'Failed to initiate direct debit.', errors: e.errors }, 400)
          end

          rescue_from Sequel::NoMatchingRow do |_e|
            error!({ message: 'Your organization does not have a credit transfer with given id!' }, 404)
          end

          ###
          ### GET /direct_debits
          ###

          desc 'Fetch a list of direct debits',
               is_array: true,
               headers: AUTH_HEADERS,
               success: Entities::V2::DirectDebit,
               failure: DEFAULT_ERROR_RESPONSES,
               produces: ['application/vnd.ebicsbox-v2+json']

          params do
            optional :iban, type: Array[String], desc: 'IBANs of account to filter', documentation: { param_type: 'query' }
            optional :page, type: Integer, desc: 'page through the results', default: 1
            optional :per_page, type: Integer, desc: 'how many results per page', values: 1..100, default: 10
          end
          get do
            query = Box::Transaction.by_organization(current_organization).direct_debits.filtered(declared(params))
            setup_pagination_header(query.count)
            present query.paginate(declared(params)).all, with: Entities::V2::DirectDebit
          end

          ###
          ### POST /direct_debits
          ###

          desc 'Create a direct debit',
               headers: AUTH_HEADERS,
               success: Message,
               body_name: 'body',
               failure: DEFAULT_ERROR_RESPONSES,
               produces: ['application/vnd.ebicsbox-v2+json'],
               detail: <<-USAGE.strip_heredoc
              Creating a debit by parameter should be the preferred way for low-volume transactions esp. for use
              cases where the PAIN XML isn’t generated before. Transactions can be transmitted either as CD1
              or CDD depending on the order types your bank is offering you, the order_type parameter
              lets you choose among them.

              sequence_types:
                - OOFF - one-off debit
                - FRST - first debit
                - RCUR - recurring debit
                - FNAL - final debit

              Once validated, transactions are transmitted asynchronously to the banking system.
              Errors that happen eventually are delivered via Webhooks
               USAGE

          params do
            requires :account, type: String, desc: 'the account to use', documentation: { param_type: 'body' }
            requires :name, type: String, desc: 'the customers name'
            requires :iban, type: String, desc: 'the customers iban'
            requires :amount_in_cents, type: Integer, desc: 'amount to debit (in cents)', values: 1..1_200_000_000
            requires :end_to_end_reference, type: String, desc: 'unique end to end reference', unique_transaction_eref: true
            requires :mandate_id, type: String, desc: 'ID of the SEPA mandate (max. 35 char)'
            requires :mandate_signature_date, type: Integer, desc: 'when the mandate was signed by the customer'
            optional :bic, type: String, desc: 'the customers bic'
            optional :reference, type: String, length: 140, desc: 'description of the transaction (max. 140 char)'
            optional :instrument, type: String, desc: '', values: %w[CORE COR1 B2B], default: 'CORE'
            optional :sequence_type, type: String, desc: '', values: %w[FRST RCUR OOFF FNAL], default: 'FRST'
            optional :instruction, type: String, desc: 'instruction identification, will not be submitted to the debtor'
            optional :execution_date, type: Date, desc: 'requested execution date', default: -> { 2.days.from_now }
          end

          post do
            account = current_organization.find_account!(params[:account])
            DirectDebit.v2_create!(current_user, account, declared(params))
            { message: 'Direct debit has been initiated successfully!' }
          end

          ###
          ### GET /direct_debits/:id
          ###

          desc 'Fetch a direct debit',
               headers: AUTH_HEADERS,
               success: Entities::V2::DirectDebit,
               failure: DEFAULT_ERROR_RESPONSES,
               produces: ['application/vnd.ebicsbox-v2+json']
          params do
            requires :id, type: String
          end
          get ':id' do
            if Box::Transaction::ID_REGEX.match(params[:id].to_s)
              direct_debit = Box::Transaction.by_organization(current_organization).direct_debits.first!(public_id: params[:id])
              present direct_debit, with: Entities::V2::DirectDebit
            else
              raise Sequel::NoMatchingRow
            end
          end
        end
      end
    end
  end
end
