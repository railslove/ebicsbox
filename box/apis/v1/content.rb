# frozen_string_literal: true

require 'active_support/core_ext/string/strip'
require 'grape'

# Validations
require_relative '../../validations/unique_transaction'

# Helpers
require_relative '../../helpers/default'
require_relative '../../helpers/pagination'

# Business processes
require_relative '../../business_processes/credit'
require_relative '../../business_processes/foreign_credit'
require_relative '../../business_processes/direct_debit'
require_relative '../../jobs/fetch_statements'
require_relative '../../jobs/fetch_upcoming_statements'

# Errors
require_relative '../../errors/business_process_failure'

# Models and entities
require_relative '../../models/account'
require_relative '../../entities/account'
require_relative '../../entities/statement'
require_relative '../../entities/transaction'

# APIs
require_relative './events'

module Box
  module Apis
    module V1
      class Content < Grape::API
        format :json
        helpers Helpers::Default
        helpers Helpers::Pagination

        AUTH_HEADERS = {
          'Authorization' => { description: 'OAuth 2 Bearer token', type: 'String' }
        }.freeze
        DEFAULT_ERROR_RESPONSES = {
          '400' => { description: 'Invalid request' },
          '401' => { description: 'Not authorized to access this resource' },
          '404' => { description: 'No account with given IBAN found' },
          '412' => { description: 'EBICS account credentials not yet activated' }
        }.freeze

        rescue_from Grape::Exceptions::ValidationErrors do |e|
          error!({
                   message: 'Validation of your request\'s payload failed!',
                   errors: Hash[e.errors.map { |k, v| [k.first, v] }]
                 }, 400)
        end

        rescue_from Account::NotActivated do |_e|
          error!({ message: 'The account has not been activated. Please activate before submitting requests!' }, 412)
        end

        rescue_from Box::BusinessProcessFailure do |e|
          error!({ message: 'Failed to initiate a business process.', errors: e.errors }, 400)
        end

        rescue_from Account::NotFound do |_e|
          error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
        end

        before do
          error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401) if current_user.nil?
        end

        include Apis::V1::Events

        params do
          optional :include, type: Array[String], desc: 'Additional data to include. Can be one of: ebics_user'
        end
        get 'accounts' do
          accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
          present accounts, with: Entities::Account, include: params[:include]
        end

        params do
          requires :account, type: String, desc: 'IBAN for an existing account'
          requires :from, type: Date, desc: 'Date from which on to filter the results'
          requires :to, type: Date, desc: 'Date to which filter results'
        end
        get ':account/import/statements', requirements: { account: /[A-Z]{2}.*/ } do
          stats = Jobs::FetchStatements.for_account(account.id, from: params[:from], to: params[:to])
          {
            message: 'Imported statements successfully',
            fetched: stats[:total],
            imported: stats[:imported]
          }
        end

        resource ':account', requirements: { account: /[A-Z]{2}.*/ } do
          params do
            requires :account, type: String, desc: 'the account to use'
            requires :name, type: String, desc: 'the customers name'
            requires :bic, type: String, desc: 'the customers bic' # TODO: validate / clearer
            requires :iban, type: String, desc: 'the customers iban' # TODO: validate
            requires :amount, type: Integer, desc: 'amount to debit (positive, charged in cents)', values: 1..1_200_000_000
            requires :eref, type: String, desc: 'end to end id', unique_transaction: true
            requires :mandate_id, type: String, desc: 'ID of the SEPA mandate (max. 35 char)'
            requires :mandate_signature_date, type: Integer, desc: 'when the mandate was signed by the customer'
            optional :instrument, type: String, desc: '', values: %w[CORE COR1 B2B], default: 'COR1'
            optional :sequence_type, type: String, desc: '', values: %w[FRST RCUR OOFF FNAL], default: 'FRST'
            optional :remittance_information, type: String, desc: 'description of the transaction (max. 140 char)'
            optional :instruction, type: String, desc: 'instruction identification, will not be submitted to the debtor'
            optional :requested_date, type: Integer, desc: 'requested execution date' # TODO: validate, future
          end
          post 'debits' do
            params[:requested_date] ||= Time.now.to_i + 172_800 # grape defaults interfere with swagger doc creation
            DirectDebit.create!(account, declared(params), current_user)
            { message: 'Direct debit has been initiated successfully!' }
          end

          params do
            requires :account, type: String, desc: 'the account to use'
            requires :name, type: String, desc: 'the customers name'
            optional :bic, type: String, desc: 'the customers bic', allow_blank: false
            requires :iban, type: String, desc: 'the customers iban'
            requires :amount, type: Integer, desc: 'amount to credit (charged in cents)', values: 1..1_200_000_000
            requires :eref, type: String, desc: 'end to end id', unique_transaction: true
            optional :remittance_information, type: String, desc: 'description of the transaction (max. 140 char)'
            optional :requested_date, type: Integer, desc: 'requested execution date'
            optional :service_level, type: String, desc: 'requested execution date', default: 'SEPA', values: %w[SEPA URGP]
          end
          post 'credits' do
            params[:requested_date] ||= Time.now.to_i # grape defaults interfere with swagger doc creation
            Credit.create!(account, declared(params), current_user)
            { message: 'Credit has been initiated successfully!' }
          end

          params do
            requires :account, type: String, desc: 'IBAN for an existing account'
            optional :transaction_id, type: Integer, desc: 'filter all statements by a specific transaction id'
            optional :page, type: Integer, desc: 'page through the results', default: 1
            optional :per_page, type: Integer, desc: 'how many results per page', values: 1..100, default: 10
            optional :from, type: Date, desc: 'Date from which on to filter the results'
            optional :to, type: Date, desc: 'Date to which filter results'
            optional :type, type: String, desc: 'Type of statement', values: %w[credit debit]
          end
          get 'statements' do
            safe_params = declared(params).to_hash.merge(account_id: account.id).symbolize_keys
            record_count = Statement.count_by_account(safe_params)
            statements = Statement.paginated_by_account(safe_params).all
            setup_pagination_header(record_count)
            present statements, with: Entities::Statement
          end

          params do
            requires :account, type: String, desc: 'IBAN for an existing account'
            optional :page, type: Integer, desc: 'page through the results', default: 1
            optional :per_page, type: Integer, desc: 'how many results per page', values: 1..100, default: 10
          end
          get 'transactions' do
            record_count = Transaction.count_by_account(account.id)
            transactions = Transaction.paginated_by_account(account.id, per_page: params[:per_page], page: params[:page]).all
            setup_pagination_header(record_count)
            present transactions, with: Entities::Transaction
          end

          params do
            requires :ebics_user, type: String, desc: 'IBAN for an existing account'
          end
          post 'ebics_users' do
            account.add_unique_ebics_user(current_user.id, params[:ebics_user])
            { message: 'EbicsUser has been created and setup successfully! INI letter has been sent via eMail.' }
          rescue StandardError => ex
            Box.logger.info { "[Content::AddEbicsUser] #{ex.message}" }
            error!({ message: ex.message }, 400)
          end

          params do
            requires :account, type: String, desc: 'the account to use'
          end
          get do
            present account, with: Entities::Account
          end
        end
      end
    end
  end
end
