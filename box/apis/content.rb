# Validations
require_relative '../validations/unique_transaction'

# Helpers
require_relative '../helpers/default'
require_relative '../helpers/pagination'

# Business processes
require_relative '../business_processes/credit'
require_relative '../business_processes/direct_debit'
require_relative '../jobs/fetch_statements'

# Errors
require_relative '../errors/business_process_failure'

# Models and entities
require_relative '../models/account'
require_relative '../models/statement'
require_relative '../entities/account'
require_relative '../entities/statement'
require_relative '../entities/transaction'

module Box
  module Apis
    class Content < Grape::API
      format :json
      helpers Helpers::Default
      helpers Helpers::Pagination

      AUTH_HEADERS = {
        'Authorization' => { description: 'OAuth 2 Bearer token', type: 'String' }
      }
      DEFAULT_ERROR_RESPONSES = {
        "400" => { description: "Invalid request" },
        "401" => { description: "Not authorized to access this resource" },
        "404" => { description: "No account with given IBAN found" },
        "412" => { description: "EBICS account credentials not yet activated" },
      }

      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error!({
          message: 'Validation of your request\'s payload failed!',
          errors: Hash[e.errors.map{ |k, v| [k.first, v]}]
        }, 400)
      end

      rescue_from Account::NotActivated do |e|
        error!({ message: 'The account has not been activated. Please activate before submitting requests!' }, 412)
      end

      rescue_from BusinessProcessFailure do |e|
        error!({ message: 'Failed to initiate a business process.', errors: e.errors }, 400)
      end

      rescue_from Account::NotFound do |e|
        error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
      end

      before do
        if current_user.nil?
          error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
        end
      end

      api_desc 'Returns a list of all accessible accounts' do
        api_name 'accounts'
        tags 'Accessible resources'
        response Entities::Account, isArray: true
        headers AUTH_HEADERS
        errors DEFAULT_ERROR_RESPONSES
      end
      get 'accounts' do
        accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
        present accounts, with: Entities::Account
      end

      resource ':account' do
        api_desc 'Returns detaild information about a single account' do
          api_name 'accounts_show'
          tags 'Account specific endpoints'
          response Entities::Account
          headers AUTH_HEADERS
          errors DEFAULT_ERROR_RESPONSES
        end
        params do
          requires :account, type: String, desc: "the account to use"
        end
        get do
          present account, with: Entities::Account
        end

        api_desc "Debit a customer's bank account" do
          api_name 'accounts_debit'
          tags 'Account specific endpoints'
          detail <<-END
  Creating a debit by parameter should be the preferred way for low-volume transactions esp. for use
  cases where the PAIN XML isn't generated before. Transactions can be transmitted either as ```CD1```
  or ```CDD``` depending on the order types your bank is offering you, the ```order_type``` parameter
  lets you choose among them.

  sequence_type

  * OOFF - one-off debit
  * FRST - first debit
  * RCUR - recurring debit
  * FNAL - final debit

  Once validated, transactions are transmitted asynchronously to the banking system.
  Errors that happen eventually are delivered via Webhooks.
  END
          headers AUTH_HEADERS
          errors DEFAULT_ERROR_RESPONSES
        end
        params do
          requires :account, type: String, desc: "the account to use"
          requires :name, type: String, desc: "the customers name"
          requires :bic, type: String, desc: "the customers bic" # TODO validate / clearer
          requires :iban, type: String, desc: "the customers iban" # TODO validate
          requires :amount, type: Integer, desc: "amount to debit (positive, charged in cents)", values: 1..12000000
          requires :eref, type: String, desc: "end to end id", unique_transaction: true
          requires :mandate_id, type: String, desc: "ID of the SEPA mandate (max. 35 char)"
          requires :mandate_signature_date, type: Integer, desc: "when the mandate was signed by the customer"
          optional :instrument, type: String, desc: "", values: %w[CORE COR1 B2B], default: "COR1"
          optional :sequence_type, type: String, desc: "", values: ["FRST", "RCUR", "OOFF", "FNAL"], default: "FRST"
          optional :remittance_information, type: String, desc: "description of the transaction (max. 140 char)"
          optional :instruction, type: String, desc: "instruction identification, will not be submitted to the debtor"
          optional :requested_date, type: Integer, desc: "requested execution date" #TODO validate, future
        end
        post 'debits' do
          params[:requested_date] ||= Time.now.to_i + 172800 # grape defaults interfere with swagger doc creation
          DirectDebit.create!(account, declared(params), current_user)
          { message: 'Direct debit has been initiated successfully!' }
        end

        api_desc "Credit a customer's bank account" do
          api_name 'account_credit'
          tags 'Account specific endpoints'
          detail <<-END
  Creating a credit by parameter should be the preferred way for low-volume transactions
  esp. for use cases where the PAIN XML isn't generated before.

  Once validated, transactions are transmitted asynchronously to the banking system. Errors
  that happen eventually are delivered via Webhooks.
  END
          headers AUTH_HEADERS
          errors DEFAULT_ERROR_RESPONSES
        end
        params do
          requires :account, type: String, desc: "the account to use"
          requires :name, type: String, desc: "the customers name"
          requires :bic , type: String, desc: "the customers bic"
          requires :iban, type: String, desc: "the customers iban"
          requires :amount, type: Integer, desc: "amount to credit (charged in cents)", values: 1..12000000
          requires :eref, type: String, desc: "end to end id", unique_transaction: true
          optional :remittance_information, type: String, desc: "description of the transaction (max. 140 char)"
          optional :requested_date, type: Integer, desc: "requested execution date"
          optional :service_level, type: String, desc: "requested execution date", default: "SEPA", values: ["SEPA", "URGP"]
        end
        post 'credits' do
          params[:requested_date] ||= Time.now.to_i # grape defaults interfere with swagger doc creation
          Credit.create!(account, declared(params), current_user)
          { message: 'Credit has been initiated successfully!' }
        end

        api_desc "Retrieve all account statements" do
          api_name 'accounts_statements'
          tags 'Account specific endpoints'
          detail "Transactions are imported on a daily basis and stored so they can be easily retrieved and searched for a timeframe that exceeds the usual timeframe your bank will hold them on record for you. Besides pulling plain lists it is also possible to filter by eref or remittance_infomation."
          headers AUTH_HEADERS
          errors DEFAULT_ERROR_RESPONSES
        end
        params do
          requires :account, type: String, desc: "IBAN for an existing account"
          optional :transaction_id, type: Integer, desc: "filter all statements by a specific transaction id"
          optional :page, type: Integer, desc: "page through the results", default: 1
          optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
          optional :from, type: Date, desc: "Date from which on to filter the results"
          optional :to, type: Date, desc: "Date to which filter results"
          optional :type, type: String, desc: "Type of statement", values: ['credit', 'debit']
        end
        get 'statements' do
          safe_params = declared(params).to_hash.merge(account_id: account.id).symbolize_keys
          record_count = Statement.count_by_account(safe_params)
          statements = Statement.paginated_by_account(safe_params).all
          setup_pagination_header(record_count)
          present statements, with: Entities::Statement
        end

        api_desc "Retrieve all executed orders" do
          api_name 'accounts_transactions'
          tags 'Account specific endpoints'
          headers AUTH_HEADERS
          errors DEFAULT_ERROR_RESPONSES
        end
        params do
          requires :account, type: String, desc: "IBAN for an existing account"
          optional :page, type: Integer, desc: "page through the results", default: 1
          optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
        end
        get 'transactions' do
          record_count = Transaction.count_by_account(account.id)
          transactions = Transaction.paginated_by_account(account.id, per_page: params[:per_page], page: params[:page]).all
          setup_pagination_header(record_count)
          present transactions, with: Entities::Transaction
        end

        namespace :import do
          api_desc "Manually import statements for a given timeframe" do
            api_name 'accounts_import_statements'
            detail "Use this endpoint to manually import statements. This might be useful if another system fetched data via STA and you now need to get this data again."
            tags 'Account specific endpoints'
            headers AUTH_HEADERS
            errors DEFAULT_ERROR_RESPONSES
          end
          params do
            requires :account, type: String, desc: "IBAN for an existing account"
            requires :from, type: Date, desc: "Date from which on to filter the results"
            requires :to, type: Date, desc: "Date to which filter results"
          end
          get 'statements' do
            stats = Jobs::FetchStatements.fetch_new_statements(account.id, params[:from], params[:to])
            {
              message: "Imported statements successfully",
              fetched: stats[:fetched],
              imported: stats[:imported],
            }
          end
        end
      end
    end
  end
end
