# Presenters
require 'epics/box/presenters/manage_account_presenter'

# Validations
require 'epics/box/validations/unique_account'
require 'epics/box/validations/active_account'

# Helpers
require 'epics/box/helpers/default'

module Epics
  module Box
    class Management < Grape::API
      format :json
      helpers Helpers::Default

      namespace :management do
        before do
          if current_user.nil?
            error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
          end
        end

        api_desc 'Entry point for management area' do
          hidden true
        end
        get '/' do
          { message: 'not yet implemented' }
        end

        resource :accounts do
          api_desc 'Retrieve a list of all onboarded accounts' do
            tags 'Account Management'
          end
          get do
            accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
            present accounts, with: ManageAccountPresenter
          end

          api_desc 'Retrieve a single account by its IBAN' do
            tags 'Account Management'
          end
          get ':id' do
            account = current_organization.accounts_dataset.first!({ iban: params[:id] })
            present account, with: ManageAccountPresenter
          end

          api_desc 'Create a new account' do
            tags 'Account Management'
          end
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
          post do
            if account = current_organization.add_account(params)
              Event.account_created(account)
              present account, with: ManageAccountPresenter
            else
              error!({ message: 'Failed to create account' }, 400)
            end
          end

          api_desc 'Submit a newly created account?' do
            tags 'Account Management'
          end
          put ':id/submit' do
            begin
              account = current_organization.accounts_dataset.first!({ iban: params[:id] })
              account.setup!
            rescue Account::AlreadyActivated => ex
              error!({ message: "Account is already activated" }, 400)
            rescue Account::IncompleteEbicsData => ex
              error!({ message: "Incomplete EBICS setup" }, 400)
            rescue => ex
              error!({ message: "unknown failure" }, 400)
            end
          end

          api_desc 'Update an existing account' do
            tags 'Account Management'
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
            begin
              account = Account.where(organization: current_organization).first!(iban: params[:id])
              account.set(params.except('id', 'state'))
              if !account.modified? || account.save
                present account, with: ManageAccountPresenter
              else
                error!({ message: 'Failed to update account' }, 400)
              end
            rescue Sequel::NoMatchingRow => ex
              error!({ message: 'Your organization does not have an account with given IBAN!' }, 400)
            end
          end
        end
      end
    end
  end
end
