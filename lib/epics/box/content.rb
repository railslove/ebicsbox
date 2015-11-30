# Validations
require 'epics/box/validations/unique_transaction'

# Helpers
require 'epics/box/helpers/default'

# Business processes
require 'epics/box/business_processes/credit'
require 'epics/box/business_processes/direct_debit'

# Errors
require 'epics/box/errors/business_process_failure'

# Models
require 'epics/box/models/account'

module Epics
  module Box
    class Content < Grape::API
      format :json
      helpers Helpers::Default

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

      before do
        if current_user.nil?
          error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
        end
      end

      resource :accounts do
        desc 'Returns a list of all accessible accounts'
        get do
          accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
          present accounts, with: AccountPresenter
        end

        desc 'Returns detaild information about a single account'
        params do
          requires :account, type: String, desc: "the account to use"
        end
        get ':account' do
          account = current_organization.accounts_dataset.first!({ iban: params[:id] })
          present account, with: AccountPresenter
        end
      end

      params do
        requires :account, type: String, desc: "the account to use"
        requires :name, type: String, desc: "the customers name"
        requires :bic, type: String, desc: "the customers bic" # TODO validate / clearer
        requires :iban, type: String, desc: "the customers iban" # TODO validate
        requires :amount, type: Integer, desc: "amount to credit", values: 1..12000000
        requires :eref, type: String, desc: "end to end id", unique_transaction: true
        requires :mandate_id, type: String, desc: "mandate id"
        requires :mandate_signature_date, type: Integer, desc: "mandate signature date"
        optional :instrument, type: String, desc: "", values: %w[CORE COR1 B2B], default: "COR1"
        optional :sequence_type, type: String, desc: "", values: ["FRST", "RCUR", "OOFF", "FNAL"], default: "FRST"
        optional :remittance_information, type: String, desc: "will apear on the customers bank statement"
        optional :instruction, type: String, desc: "instruction identification, will not be submitted to the debtor"
        optional :requested_date, type: Integer, desc: "requested execution date" #TODO validate, future
      end
      desc "debits a customer account"
      post ':account/debits' do
        begin
          params[:requested_date] ||= Time.now.to_i + 172800 # grape defaults interfere with swagger doc creation
          DirectDebit.create!(account, params, current_user)
          { message: 'Direct debit has been initiated successfully!' }
        rescue Sequel::NoMatchingRow => e
          error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
        end
      end

      params do
        requires :account, type: String, desc: "the account to use"
        requires :name, type: String, desc: "the customers name"
        requires :bic , type: String, desc: "the customers bic"
        requires :iban, type: String, desc: "the customers iban"
        requires :amount, type: Integer, desc: "amount to credit", values: 1..12000000
        requires :eref, type: String, desc: "end to end id", unique_transaction: true
        optional :remittance_information, type: String, desc: "will apear on the customers bank statement"
        optional :requested_date, type: Integer, desc: "requested execution date"
        optional :service_level, type: String, desc: "requested execution date", default: "SEPA", values: ["SEPA", "URGP"]
      end
      post ':account/credits' do
        begin
          params[:requested_date] ||= Time.now.to_i
          Credit.create!(account, params, current_user)
          { message: 'Credit has been initiated successfully!' }
        rescue Sequel::NoMatchingRow => e
          error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
        end
      end

      desc "Returns statements for account"
      params do
        requires :account, type: String, desc: "IBAN for an existing account"
        optional :from, type: Integer, desc: "results starting at"
        optional :to, type: Integer, desc: "results ending at"
        optional :page, type: Integer, desc: "page through the results", default: 1
        optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
      end
      get ':account/statements' do
        begin
          statements = Statement.paginated_by_account(account.id, per_page: params[:per_page], page: params[:page]).all
          # statements = Statement.where(account_id: account.id).limit(params[:per_page]).offset((params[:page] - 1) * params[:per_page]).all
          present statements, with: Epics::Box::StatementPresenter
        rescue Sequel::NoMatchingRow => ex
          error!({ message: 'Your organization does not have an account with given IBAN!' }, 404)
        end
      end

      desc "Returns transactions for account"
      params do
        requires :account, type: String, desc: "IBAN for an existing account"
        optional :page, type: Integer, desc: "page through the results", default: 1
        optional :per_page, type: Integer, desc: "how many results per page", values: 1..100, default: 10
      end
      get ':account/transactions' do
        begin
          statements = Transaction.paginated_by_account(account.id, per_page: params[:per_page], page: params[:page]).all
          present statements, with: Epics::Box::TransactionPresenter
        rescue Sequel::NoMatchingRow => ex
          { errors: "no account found error: #{ex.message}" }
        end
      end
    end
  end
end
