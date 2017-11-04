require 'grape'

# Helpers
require_relative '../../helpers/default'

module Box
  module Apis
    module V1
      class Service < Grape::API
        format :json
        helpers Helpers::Default

        before do
          if current_user.nil?
            error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
          end
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
            version: 'v1',
          }
        end
      end
    end
  end
end
