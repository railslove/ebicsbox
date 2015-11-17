# Validations
require 'epics/box/validations/unique_transaction'

# Helpers
require 'epics/box/helpers/default'

module Epics
  module Box
    class Content < Grape::API
      format :json
      helpers Helpers::Default

      before do
        if current_user.nil?
          error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
        end
      end

      resource :accounts do
        get do
          accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
          present accounts, with: AccountPresenter
        end

        params do
          requires :account, type: String, desc: "the account to use"
        end
        get ':account' do
          account = current_organization.accounts_dataset.first!({ iban: params[:id] })
          present account, with: AccountPresenter
        end
      end

      params do
        requires :account,  type: String, desc: "the account to use"
        requires :name,  type: String, desc: "the customers name"
        requires :bic ,  type: String, desc: "the customers bic" # TODO validate / clearer
        requires :iban ,  type: String, desc: "the customers iban" # TODO validate
        requires :amount,  type: Integer, desc: "amount to credit", values: 1..12000000
        requires :eref,  type: String, desc: "end to end id", unique_transaction: true
        requires :mandate_id,  type: String, desc: "mandate id"
        requires :mandate_signature_date, type: Integer, desc: "mandate signature date"
        optional :instrument, type: String, desc: "", values: %w[CORE COR1 B2B], default: "COR1"
        optional :sequence_type, type: String, desc: "", values: ["FRST", "RCUR", "OOFF", "FNAL"], default: "FRST"
        optional :remittance_information ,  type: String, desc: "will apear on the customers bank statement"
        optional :instruction,  type: String, desc: "instruction identification, will not be submitted to the debtor"
        optional :requested_date,  type: Integer, desc: "requested execution date", default: ->{ Time.now.to_i + 172800 } #TODO validate, future
      end
      desc "debits a customer account"
      post ':account/debits' do
        begin
          sdd = SEPA::DirectDebit.new(account.pain_attributes_hash).tap do |credit|
            credit.message_identification= "EBICS-BOX/#{SecureRandom.hex(11).upcase}"
            credit.add_transaction(
              name: params[:name],
              bic: params[:bic],
              iban: params[:iban],
              amount: params[:amount] / 100.0,
              instruction: params[:instruction],
              mandate_id: params[:mandate_id],
              mandate_date_of_signature: Time.at(params[:mandate_signature_date]).to_date,
              local_instrument: params[:instrument],
              sequence_type: params[:sequence_type],
              reference: params[:eref],
              remittance_information: params[:remittance_information],
              requested_date: Time.at(params[:requested_date]).to_date,
              batch_booking: true
            )
          end

          fail(RuntimeError.new(sdd.errors.full_messages.join(" "))) unless sdd.valid?

          Queue.execute_debit(
            account_id: account.id,
            user_id: current_user.id,
            payload: Base64.strict_encode64(sdd.to_xml),
            amount: params[:amount],
            eref: params[:eref],
            instrument: params[:instrument]
          )

          {debit: 'ok'}
        rescue RuntimeError, ArgumentError => e
          {debit: 'nok', error: e.message}
        rescue Sequel::NoMatchingRow => e
          {credit: 'nok', errors: 'no account found'}
        end
      end

      params do
        requires :account,  type: String, desc: "the account to use"
        requires :name,  type: String, desc: "the customers name"
        requires :bic ,  type: String, desc: "the customers bic"
        requires :iban ,  type: String, desc: "the customers iban"
        requires :amount,  type: Integer, desc: "amount to credit", values: 1..12000000
        requires :eref,  type: String, desc: "end to end id", unique_transaction: true
        optional :remittance_information ,  type: String, desc: "will apear on the customers bank statement"
        optional :requested_date,  type: Integer, desc: "requested execution date", default: ->{ Time.now.to_i }
        optional :service_level, type: String, desc: "requested execution date", default: "SEPA", values: ["SEPA", "URGP"]
      end
      desc "Credits a customer account"
      post ':account/credits' do
        begin
          sct = SEPA::CreditTransfer.new(account.credit_pain_attributes_hash).tap do |credit|
            credit.message_identification= "EBICS-BOX/#{SecureRandom.hex(11).upcase}"
            credit.add_transaction(
              name: params[:name],
              bic: params[:bic],
              iban: params[:iban],
              amount: params[:amount] / 100.0,
              reference: params[:eref],
              remittance_information: params[:remittance_information],
              requested_date: Time.at(params[:requested_date]).to_date,
              batch_booking: true,
              service_level: params[:service_level]
            )
          end

          fail(RuntimeError.new(sct.errors.full_messages.join(" "))) unless sct.valid?

          Queue.execute_credit(
            account_id: account.id,
            user_id: current_user.id,
            payload: Base64.strict_encode64(sct.to_xml),
            eref: params[:eref],
            amount: params[:amount]
          )

          {credit: 'ok'}
        rescue RuntimeError, ArgumentError => e
          {credit: 'nok', errors: sct.errors.to_hash}
        rescue Sequel::NoMatchingRow => e
          {credit: 'nok', errors: 'no account found'}
        end
      end

      desc "Returns statements for account"
      params do
        requires :account,  type: String, desc: "IBAN for an existing account"
        optional :from,  type: Integer, desc: "results starting at"
        optional :to,    type: Integer, desc: "results ending at"
        optional :page,  type: Integer, desc: "page through the results", default: 1
        optional :per_page,  type: Integer, desc: "how many results per page", values: 1..100, default: 10
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
        requires :account,  type: String, desc: "IBAN for an existing account"
        optional :page,  type: Integer, desc: "page through the results", default: 1
        optional :per_page,  type: Integer, desc: "how many results per page", values: 1..100, default: 10
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
