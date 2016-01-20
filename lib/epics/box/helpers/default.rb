require_relative '../models/user'
require_relative '../server'

module Epics
  module Box
    module Helpers
      module Default
        def access_token
          params['access_token'] || headers['Authorization'].to_s[/token (.+)/, 1]
        end

        def current_user
          @current_user ||= User.find_by_access_token(access_token)
        end

        def current_organization
          @current_organization ||= current_user.organization
        end

        def account
          current_organization.find_account!(params[:account])
        end

        def logger
          Server.logger
        end
      end
    end
  end
end
