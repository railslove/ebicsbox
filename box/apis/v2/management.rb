require 'grape'

require_relative './api_endpoint'

# Validations
require_relative '../../validations/unique_account'
require_relative '../../validations/active_account'
require_relative '../../validations/unique_subscriber'

# Helpers
require_relative '../../helpers/default'

# Entities
require_relative '../../entities/management_account'
require_relative '../../entities/user'

module Box
  module Apis
    module V2
      class Management < Grape::API
        include ApiEndpoint
        content_type :html, 'text/html'

        namespace :management do
          before do
            unless env['box.admin']
              error!({ message: 'Unauthorized access. Please provide a valid organization management token!' }, 401)
            end
          end

          desc 'Service', hidden: true
          get '/' do
            { message: 'not yet implemented' }
          end

          resource :accounts do
            ###
            ### GET /management/accounts
            ###
            desc 'Retrieve a list of all onboarded accounts',
              tags: ['account management'],
              is_array: true,
              headers: AUTH_HEADERS,
              success: Entities::V2::Account,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']

            get do
              accounts = current_organization.accounts_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
              present accounts, with: Entities::ManagementAccount
            end

            ###
            ### GET /management/accounts/DExx
            ###
            desc 'Retrieve a single account by its IBAN',
              tags: ['account management'],
              headers: AUTH_HEADERS,
              success: Entities::V2::Account,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']
            params do
              requires :iban, type: String
            end

            get ':iban' do
              begin
                account = current_organization.accounts_dataset.first!(iban: params[:iban])
                present account, with: Entities::ManagementAccount, type: 'full'
              rescue Sequel::NoMatchingRow
                error!({ message: 'Your organization does not have an account with given IBAN!' }, 400)
              end
            end

            ###
            ### POST /management/accounts
            ###
            desc 'Create a new account',
              tags: ['account management'],
              body_name: 'body',
              headers: AUTH_HEADERS,
              success: Entities::V2::Account,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']

            params do
              requires :name, type: String, unique_account: true, allow_blank: false, desc: 'Internal description of account', documentation: { param_type: 'body' }
              requires :iban, type: String, unique_account: true, allow_blank: false, desc: 'IBAN'
              requires :bic, type: String, allow_blank: false, desc: 'BIC'
              optional :bankname, type: String, desc: 'Name of bank (for internal purposes)'
              optional :creditor_identifier, type: String, desc: 'creditor_identifier'
              optional :callback_url, type: String, desc: 'callback_url'
              optional :host, type: String, desc: 'host'
              optional :partner, type: String, desc: 'partner'
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

            desc 'Setup a newly created account',
              tags: ['account management'],
              headers: AUTH_HEADERS,
              success: Message,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']

            params do
              requires :iban, type: String
            end
            put ':iban/setup' do
              begin
                account = current_organization.accounts_dataset.first!(iban: params[:iban])
                account.setup!
              rescue Account::AlreadyActivated
                error!({ message: "Account is already activated" }, 400)
              rescue Account::IncompleteEbicsData
                error!({ message: "Incomplete EBICS setup" }, 400)
              rescue
                error!({ message: "unknown failure" }, 400)
              end
            end

            desc 'Update an existing account',
              tags: ['account management'],
              headers: AUTH_HEADERS,
              success: Entities::ManagementAccount,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']

            params do
              optional :name, type: String, unique_account: true, allow_blank: false, desc: 'Internal description of account', documentation: { param_type: 'body' }
              optional :bankname, type: String, desc: 'Name of bank (for internal purposes)'
              optional :creditor_identifier, type: String, desc: 'creditor_identifier'
              optional :callback_url, type: String, desc: 'callback_url'
              optional :host, type: String, desc: 'host'
              optional :partner, type: String, desc: 'partner'
              optional :url, type: String, desc: 'url'
              optional :mode, type: String, desc: 'mode'
            end
            put ':iban' do
              begin
                account = current_organization.accounts_dataset.first!(iban: params[:iban])
                account.set(params.except('id', 'state', 'access_token', 'iban', 'bic'))
                if !account.modified? || account.save
                  present account, with: Entities::ManagementAccount
                else
                  error!({ message: 'Failed to update account' }, 400)
                end
              rescue Sequel::NoMatchingRow
                error!({ message: 'Your organization does not have an account with given IBAN!' }, 400)
              end
            end
          end

          resource 'accounts/:iban/subscribers' do
            desc 'Fetch an account\'s INI letter',
              tags: ['subscriber management']

            get ':id/ini_letter' do
              subscriber = Subscriber.join(:accounts, id: :account_id).where(organization_id: current_organization.id, iban: params[:iban]).first!(Sequel.qualify(:subscribers, :id) => params[:id])
              if subscriber.ini_letter.nil?
                error!({ message: 'Subscriber setup not yet initiated!' }, 412)
              else
                content_type 'text/html'
                subscriber.ini_letter
              end
            end

            desc 'Retrieve a list of all subscribers for given account',
              tags: ['subscriber management'],
              headers: AUTH_HEADERS,
              success: Entities::Subscriber,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']
            get do
              account = current_organization.accounts_dataset.first!(iban: params[:iban])
              present account.subscribers, with: Entities::Subscriber
            end

            desc 'Add a subscriber to given account',
              tags: ['subscriber management'],
              body_name: 'body',
              headers: AUTH_HEADERS,
              success: Entities::Subscriber,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']
            params do
              requires :user_id, type: Integer, desc: "Internal user identifier to associate the subscriber with", documentation: { param_type: 'body' }
              requires :ebics_user, type: String, unique_subscriber: true, desc: "EBICS user to represent"
            end
            post do
              account = current_organization.accounts_dataset.first!(iban: params[:iban])
              declared_params = declared(params)
              ebics_user = declared_params.delete(:ebics_user)
              subscriber = account.add_subscriber(declared_params.merge(remote_user_id: ebics_user))
              if subscriber
                if subscriber.setup!
                  present subscriber, with: Entities::Subscriber
                else
                  subscriber.destroy
                  error!({ message: 'Failed to setup subscriber. Make sure your data is valid and retry!' }, 412)
                end
              else
                error!({ message: 'Failed to create subscriber' }, 400)
              end
            end
          end

          resource :users do
            desc 'Retrieve a list of all users',
              tags: ['user management'],
              is_array: true,
              headers: AUTH_HEADERS,
              success: Entities::User,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']
            get do
              users = current_organization.users_dataset.all.sort { |a1, a2| a1.name.to_s.downcase <=> a2.name.to_s.downcase }
              present users, with: Entities::User
            end

            desc 'Retrieve a single user by its identifier',
              tags: ['user management'],
              headers: AUTH_HEADERS,
              success: Entities::User,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']
            get ':id' do
              user = current_organization.users_dataset.first!({ id: params[:id] })
              present user, with: Entities::User, type: 'full'
            end

            desc 'Create a new user instance',
              tags: ['user management'],
              body_name: 'body',
              headers: AUTH_HEADERS,
              success: Entities::User,
              failure: DEFAULT_ERROR_RESPONSES,
              produces: ['application/vnd.ebicsbox-v2+json']
            params do
              requires :name, type: String, desc: "The user's display name", documentation: { param_type: 'body' }
              optional :token, type: String, desc: 'Set a custom access token'
            end
            post do
              token = params[:token] || SecureRandom.hex
              if user = current_organization.add_user(name: params[:name], access_token: token)
                present user, with: Entities::User, include_token: true
              else
                error!({ message: 'Failed to create user' }, 400)
              end
            end
          end
        end
      end
    end
  end
end
