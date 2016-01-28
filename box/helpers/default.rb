require_relative '../models/organization'
require_relative '../models/user'
require_relative '../api'

module Box
  module Helpers
    module Default
      def access_token
        params['access_token'] || headers['Authorization'].to_s[/token (.+)/, 1]
      end

      def current_user
        @current_user ||= User.find_by_access_token(access_token)
      end

      def managed_organization
        @managed_organization ||= Organization.find_by_management_token(access_token)
      end

      def current_organization
        @current_organization ||= request.path.match(/^\/management/i) ? managed_organization : current_user.organization
      end

      def account
        current_organization.find_account!(params[:account])
      end

      def logger
        Api.logger
      end
    end
  end
end
