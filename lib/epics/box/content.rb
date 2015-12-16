# Validations
require 'epics/box/validations/unique_transaction'

# Helpers
require 'epics/box/helpers/default'

# Business processes
require 'epics/box/business_processes/credit'
require 'epics/box/business_processes/direct_debit'

# Errors
require 'epics/box/errors/business_process_failure'

# Models and entities
require 'epics/box/models/account'
require 'epics/box/entities/account'

module Epics
  module Box
    class Content < Grape::API
      format :json
      helpers Helpers::Default

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

      resource :accounts do
        api_desc 'Returns a list of all accessible accounts' do
          api_name 'accounts'
          tags 'Accounts'
          response Entities::Account, isArray: true
          headers AUTH_HEADERS
          errors DEFAULT_ERROR_RESPONSES
        end
        get do
          accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
          present accounts, with: Entities::Account
        end

        api_desc 'Returns detaild information about a single account' do
          api_name 'accounts_show'
          tags 'Accounts'
          response Entities::Account
          headers AUTH_HEADERS
          errors DEFAULT_ERROR_RESPONSES
        end
        params do
          requires :account, type: String, desc: "the account to use"
        end
        get ':account' do
          present account, with: Entities::Account
        end
      end

      api_desc "Debit a customer's bank account" do
        api_name 'accounts_debit'
        tags 'Orders'
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
      post ':account/debits' do
        params[:requested_date] ||= Time.now.to_i + 172800 # grape defaults interfere with swagger doc creation
        DirectDebit.create!(account, params, current_user)
        { message: 'Direct debit has been initiated successfully!' }
      end

      api_desc "Credit a customer's bank account" do
        api_name 'accounts_credit'
        tags 'Orders'
        detail <<-END
Creating a credit by parameter should be the preferred way for low-volume transactions
esp. for use cases where the PAIN XML isn't generated before.

Once validated, transactions are transmitted asynchronously to the banking system. Errors
that happen eventually are delivered via Webhooks.
END
        headers AUTH_HEADERS
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
      post ':account/credits' do
        params[:requested_date] ||= Time.now.to_i # grape defaults interfere with swagger doc creation
        Credit.create!(account, params, current_user)
        { message: 'Credit has been initiated successfully!' }
      end

      api_desc "Retrieve all account statements" do
        api_name 'accounts_statements'
        tags 'Orders'
        detail <<-END
Transactions are imported on a daily basis and stored so they can be easily retrieved and searched
for a timeframe that exceeds the usual timeframe your bank will hold them on record for you. Besides
pulling plain lists it is also possible to filter by eref or remittance_infomation.
END
        headers AUTH_HEADERS
      end
      params do
        requires :account, type: String, desc: "IBAN for an existing account"
        optional :from, type: Integer, desc: "results starting at"
        optional :to, type: Integer, desc: "results ending at"
        optional :page, type: Integer, desc: "page through the results", default: 1
        optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
      end
      get ':account/statements' do
        statements = Statement.paginated_by_account(account.id, per_page: params[:per_page], page: params[:page]).all
        present statements, with: StatementPresenter
      end

      api_desc "Retrieve all executed orders" do
        api_name 'accounts_transactions'
        tags 'Orders'
        headers AUTH_HEADERS
      end
      params do
        requires :account, type: String, desc: "IBAN for an existing account"
        optional :page, type: Integer, desc: "page through the results", default: 1
        optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
      end
      get ':account/transactions' do
        statements = Transaction.paginated_by_account(account.id, per_page: params[:per_page], page: params[:page]).all
        present statements, with: TransactionPresenter
      end
    end
  end
end
