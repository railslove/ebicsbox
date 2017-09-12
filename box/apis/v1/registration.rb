require 'grape'

require_relative '../../models/organization'
require_relative '../../entities/registration_organization'

module Box
  module Apis
    module V1
      class Registration < Grape::API
        format :json

        before do
          unless Box.configuration.registrations_allowed?
            error!({ message: "Registration is not enabled. Please contact an admin!" }, 405)
          end
        end

        rescue_from Grape::Exceptions::ValidationErrors do |e|
          error!({
            message: 'Validation of your request\'s payload failed!',
            errors: Hash[e.errors.map{ |k, v| [k.first, v]}]
          }, 400)
        end

        params do
          requires :name, type: String, desc: "The organization's display name"
          requires :user, type: Hash do
            requires :name, type: String, desc: "The user's display name"
            optional :access_token, type: String, desc: 'Set a custom access token'
          end
          optional :webhook_token, type: String, desc: "Token to sign organization's webhook payloads"
        end
        post '/organizations' do
          begin
            DB.transaction do
              user_token = (params[:user][:access_token] || SecureRandom.hex)
              organization = Organization.register(declared(params).except(:user))
              user = organization.add_user(name: params[:user][:name], access_token: user_token, admin: true)
              present organization, with: Entities::RegistrationOrganization
            end
          rescue => ex
            Box.logger.error("[Registration] #{ex.message}")
            error!({ message: "Failed to create organization!" }, 400)
          end
        end
      end
    end
  end
end
