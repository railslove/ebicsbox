require 'jwt'

require_relative '../models/organization'
require_relative '../models/user'

module Box
  module Helpers
    module Default
      def current_user
        env['box.user']
      end

      def current_organization
        env['box.organization']
      end

      def account
        current_organization.find_account!(params[:account])
      end

      def logger
        Box.logger
      end
    end
  end
end
