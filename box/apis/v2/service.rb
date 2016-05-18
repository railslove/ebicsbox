require 'grape'

require_relative '../../helpers/default'

module Box
  module Apis
    module V2
      class Service < Grape::API
        helpers Helpers::Default

        before do
          if current_user.nil?
            error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
          end
        end

        get do
          {
            version: 'v2'
          }
        end
      end
    end
  end
end
