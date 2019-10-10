# frozen_string_literal: true

require 'grape'

require_relative '../api_endpoint'

# Helpers
require_relative '../../../helpers/default'

# Entities
require_relative '../../../entities/user'

module Box
  module Apis
    module V2
      module Management
        class Users < Grape::API
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
              # index
              desc 'Retrieve a list of all users',
                   tags: ['user management'],
                   is_array: true,
                   headers: AUTH_HEADERS,
                   success: Entities::User,
                   failure: DEFAULT_ERROR_RESPONSES,
                   produces: ['application/vnd.ebicsbox-v2+json']

              get do
                users = current_organization.users_dataset.order(:name).all
                present users, with: Entities::User, type: 'full', include_admin_state: true
              end

              # show
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
                present user, with: Entities::User, type: 'full', include_token: true, include_admin_state: true
              rescue Sequel::NoMatchingRow
                error!({ message: 'User not found' }, 404)
              end

              # new
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
                user = current_organization.add_user(declared(params))
                if user
                  present user, with: Entities::User, include_token: true
                else
                  error!({ message: 'Failed to create user' }, 400)
                end
              end

              # delete
              desc 'Deletes a user instance',
                   tags: ['user management'],
                   body_name: 'body',
                   headers: AUTH_HEADERS,
                   failure: DEFAULT_ERROR_RESPONSES,
                   produces: ['application/vnd.ebicsbox-v2+json']

              params do
                requires :id, type: Integer, desc: "The user's id", documentation: { param_type: 'body' }
              end

              delete ':id' do
                user = Box::User[params[:id]]
                return error!({ message: 'User not found' }, 404) unless user

                user.destroy
                status 204
              end
            end
          end
        end
      end
    end
  end
end
