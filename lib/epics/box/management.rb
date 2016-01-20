# Validations
require 'epics/box/validations/unique_account'
require 'epics/box/validations/active_account'

# Helpers
require 'epics/box/helpers/default'

# Entities
require 'epics/box/entities/management_account'
require 'epics/box/entities/user'

module Epics
  module Box
    class Management < Grape::API
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

      namespace :management do
        before do
          if managed_organization.nil?
            error!({ message: 'Unauthorized access. Please provide a valid organization management token token!' }, 401)
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
            api_name 'management_accounts'
            tags 'Management'
            response Entities::ManagementAccount, isArray: true
            headers AUTH_HEADERS
            errors DEFAULT_ERROR_RESPONSES
          end
          get do
            accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
            present accounts, with: Entities::ManagementAccount
          end

          api_desc 'Retrieve a single account by its IBAN' do
            api_name 'management_account'
            tags 'Management'
            response Entities::ManagementAccount
            headers AUTH_HEADERS
            errors DEFAULT_ERROR_RESPONSES
          end
          get ':id' do
            account = current_organization.accounts_dataset.first!({ iban: params[:id] })
            present account, with: Entities::ManagementAccount, type: 'full'
          end

          api_desc 'Create a new account' do
            tags 'Management'
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
              present account, with: Entities::ManagementAccount
            else
              error!({ message: 'Failed to create account' }, 400)
            end
          end

          api_desc 'Submit a newly created account?' do
            tags 'Management'
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
            tags 'Management'
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
                present account, with: Entities::ManagementAccount
              else
                error!({ message: 'Failed to update account' }, 400)
              end
            rescue Sequel::NoMatchingRow => ex
              error!({ message: 'Your organization does not have an account with given IBAN!' }, 400)
            end
          end
        end

        resource :users do
          api_desc 'Retrieve a list of all users' do
            api_name 'management_users'
            tags 'Management'
            response Entities::User, isArray: true
            headers AUTH_HEADERS
            errors DEFAULT_ERROR_RESPONSES
          end
          get do
            users = current_organization.users_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
            present users, with: Entities::User
          end

          api_desc 'Retrieve a single user by its identifier' do
            api_name 'management_user'
            tags 'Management'
            response Entities::User
            headers AUTH_HEADERS
            errors DEFAULT_ERROR_RESPONSES
          end
          get ':id' do
            user = current_organization.users_dataset.first!({ id: params[:id] })
            present user, with: Entities::User, type: 'full'
          end

          api_desc 'Create a new user instance' do
            api_name 'management_user_create'
            tags 'Management'
            headers AUTH_HEADERS
            errors DEFAULT_ERROR_RESPONSES
          end
          params do
            requires :name, type: String, desc: "The user's display name"
          end
          post do
            if user = current_organization.add_user(params.merge(access_token: SecureRandom.hex))
              {
                message: 'User has been created successfully!',
                user: Entities::User.represent(user),
              }
            else
              error!({ message: 'Failed to create user' }, 400)
            end
          end
        end
      end
    end
  end
end
