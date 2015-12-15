# Helpers
require 'epics/box/helpers/default'

module Epics
  module Box
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
        "Home"
      end
    end
  end
end
