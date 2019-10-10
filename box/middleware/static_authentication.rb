# frozen_string_literal: true

require 'rack'
require_relative '../models/user'
require_relative '../models/organization'

module Box
  module Middleware
    class StaticAuthentication
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        auth_data = load_user_auth_data(request)
        @app.call(env.merge(auth_data))
      end

      private

      def load_user_auth_data(request)
        access_token = request.params['access_token'] || request.env['HTTP_AUTHORIZATION'].to_s[/\A(?:token|Bearer) (.+)\z/, 1]
        user = User.find_by_access_token(access_token)

        {
          'box.user' => user,
          'box.organization' => user.try(:organization),
          'box.admin' => user.try(:admin)
        }
      end
    end
  end
end
