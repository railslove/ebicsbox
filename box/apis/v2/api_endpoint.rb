require 'active_support/concern'

require_relative '../../helpers/pagination'

module Box
  module Apis
    module V2
      module ApiEndpoint
        extend ActiveSupport::Concern

        included do
          version 'v2', using: :header, vendor: 'ebicsbox'
          format :json
          helpers Helpers::Pagination

          helpers do
            def current_user
              env['box.user']
            end

            def current_organization
              env['box.organization']
            end

            def logger
              Box.logger
            end
          end

          before do
            if current_user.nil?
              error!({ message: 'Unauthorized access. Please provide a valid access token!' }, 401)
            end
          end

          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!({
              message: 'Validation of your request\'s payload failed!',
              errors: Hash[e.errors.map{ |k, v| [k.first, v]}]
            }, 400)
          end
        end
      end
    end
  end
end
