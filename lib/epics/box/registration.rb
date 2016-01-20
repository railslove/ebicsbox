require 'grape'

require_relative 'models/organization'
require_relative 'entities/registration_organization'

module Epics
  module Box
    class Registration < Grape::API
      format :json

      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error!({
          message: 'Validation of your request\'s payload failed!',
          errors: Hash[e.errors.map{ |k, v| [k.first, v]}]
        }, 400)
      end

      api_desc 'Create a new organization' do
        api_name 'registration_organization'
        tags 'Registration'
      end
      params do
        requires :name, type: String, desc: "The organization's display name"
        optional :management_token, type: String, desc: "Token to access organization's management features"
      end
      post '/organizations' do
        if organization = Organization.register(declared(params))
          present organization, with: Entities::RegistrationOrganization
        else
          error!({ message: "Failed to create organization!" }, 400)
        end
      end
    end
  end
end
