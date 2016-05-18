require 'grape'
require 'ruby-swagger/grape/grape'

# Helpers
require_relative '../helpers/default'

module Box
  module Apis
    class Service < Grape::API
      format :json
      helpers Helpers::Default

      before do
        if current_user.nil?
          error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
        end
      end

      api_desc 'Renders homepage with most relevant information' do
        tags 'Service'
      end
      get '/' do
        {
          documentation: Box.configuration.app_url + '/docs',
          management: {
            accounts: Box.configuration.app_url + "/management/accounts",
          },
          resources: {
            accounts: Box.configuration.app_url + "/accounts",
          },
        }
      end
    end
  end
end
