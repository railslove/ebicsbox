require 'grape'

require_relative '../api_endpoint'

# Helpers
require_relative '../../../helpers/default'

# Entities
require_relative '../../../entities/user'

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

          resource :users do
            desc 'Retrieve a list of all users',
                 tags: ['user management'],
                 is_array: true,
                 headers: AUTH_HEADERS,
                 success: Entities::User,
                 failure: DEFAULT_ERROR_RESPONSES,
                 produces: ['application/vnd.ebicsbox-v2+json']

            get do
              users = current_organization.users_dataset.order(:name).all
              present users, with: Entities::User, type: 'full'
            end

            desc 'Retrieve a single user by its identifier',
                 tags: ['user management'],
                 headers: AUTH_HEADERS,
                 success: Entities::User,
                 failure: DEFAULT_ERROR_RESPONSES,
                 produces: ['application/vnd.ebicsbox-v2+json']

            params do
              requires :id, type: Integer, desc: 'ID of the user'
            end
            get ':id' do
              user = current_organization.users_dataset.first!(id: params[:id])
              present user, with: Entities::User, type: 'full', include_token: true
            rescue Sequel::NoMatchingRow
              error!({ message: 'User not found' }, 404)
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
              if user = current_organization.add_user(name: params[:name], access_token: params[:token])
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
