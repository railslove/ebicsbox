require 'epics/box/presenters/manage_account_presenter'

module Epics
  module Box
    class Server < Grape::API
      class Unique < Grape::Validations::Base
        def validate_param!(attr_name, params)
          unless DB[:transactions].where(attr_name => params[attr_name]).count == 0
            raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be unique"
          end
        end
      end

      class UniqueAccount < Grape::Validations::Base
        def validate_param!(attr_name, params)
          account = Account.first(attr_name => params[attr_name])

          adding_duplicate_iban = account.present? && params[:id].blank?
          changing_to_duplicate_iban = account.present? && params[:id].present? && params[:id] != account.iban

          if adding_duplicate_iban || changing_to_duplicate_iban
            raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be unique"
          end
        end
      end

      class ActiveAccount < Grape::Validations::Base
        def validate_param!(attr_name, params)
          account = Account.first!(iban: params[:id])
          if account.iban != params[:iban] && account.active?
            raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "cannot be changed on active account"
          end
        end
      end

      format :json

      before do
        if current_user.nil?
          error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
        end
      end

      helpers do
        def current_user
          @current_user ||= begin
            if match = env['Authorization'].to_s.match(/token (.+)/)
              User.find_by_access_token(match[1])
            else
              nil
            end
          end
        end

        def account
          Epics::Box::Account.first!({iban: params[:account]})
        end

        def logger
          Server.logger
        end
      end

      get '/' do
        "Home"
      end

      resource :accounts do
        params do
          requires :name, type: String, unique_account: true, allow_blank: false, desc: 'Internal description of account'
          requires :iban, type: String, unique_account: true, allow_blank: false, desc: 'IBAN'
          requires :bic, type: String, allow_blank: false, desc: 'BIC'
          optional :bankname, type: String, desc: 'Name of bank (for internal purposes)'
          optional :creditor_identifier, type: String, desc: 'creditor_identifier'
          optional :callback_url, type: String, desc: 'callback_url'
          optional :host, type: String, desc: 'host'
          optional :partner, type: String, desc: 'partner'
          optional :user, type: String, desc: 'user'
          optional :url, type: String, desc: 'url'
          optional :mode, type: String, desc: 'mode'
        end
        desc 'Add a new account'
        post do
          if account = Account.create(params)
            Event.account_created(account)
            present account, with: ManageAccountPresenter
          else
            error!({ message: 'Failed to create account' }, 400)
          end
        end

        get do
          accounts = Account.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
          present accounts, with: ManageAccountPresenter
        end

        get ':id' do
          account = Account.first!({ iban: params[:id] })
          present account, with: ManageAccountPresenter
        end

        put ':id/submit' do
          begin
            account = Account.first!({ iban: params[:id] })
            account.setup!
          rescue Account::AlreadyActivated => ex
            error!({ message: "Account is already activated" }, 400)
          rescue Account::IncompleteEbicsData => ex
            error!({ message: "Incomplete EBICS setup" }, 400)
          rescue => ex
            error!({ message: "unknown failure" }, 400)
          end
        end

        params do
          optional :name, type: String, unique_account: true, allow_blank: false, desc: 'Internal description of account'
          optional :iban, type: String, unique_account: true, active_account: false, allow_blank: false, desc: 'IBAN'
          optional :bic, type: String, active_account: false, allow_blank: false, desc: 'BIC'
          optional :bankname, type: String, desc: 'Name of bank (for internal purposes)'
          optional :creditor_identifier, type: String, desc: 'creditor_identifier'
          optional :callback_url, type: String, desc: 'callback_url'
          optional :host, type: String, desc: 'host'
          optional :partner, type: String, desc: 'partner'
          optional :user, type: String, desc: 'user'
          optional :url, type: String, desc: 'url'
          optional :mode, type: String, desc: 'mode'
        end
        put ':id' do
          account = Account.find(iban: params[:id])
          account.set(params.except('id', 'state'))
          if !account.modified? || account.save
            present account, with: ManageAccountPresenter
          else
            error!({ message: 'Failed to update account' }, 400)
          end
        end
      end

      params do
        requires :account,  type: String, desc: "the account to use"
        requires :name,  type: String, desc: "the customers name"
        requires :bic ,  type: String, desc: "the customers bic" # TODO validate / clearer
        requires :iban ,  type: String, desc: "the customers iban" # TODO validate
        requires :amount,  type: Integer, desc: "amount to credit", values: 1..12000000
        requires :eref,  type: String, desc: "end to end id", unique: true
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

          Queue.execute_debit account_id: account.id, payload: Base64.strict_encode64(sdd.to_xml), amount: params[:amount], eref: params[:eref], instrument: params[:instrument]

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
        requires :eref,  type: String, desc: "end to end id", unique: true
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

          Queue.execute_credit account_id: account.id, payload: Base64.strict_encode64(sct.to_xml), eref: params[:eref], amount: params[:amount]

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
          { errors: "no account found error: #{ex.message}" }
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
