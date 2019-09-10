require 'faraday'
require 'jwt'
require 'uri'

require_relative '../models/user'
require_relative '../models/organization'

module Box
  module Middleware
    class OauthAuthentication
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
        data = JWT.decode(access_token, Box.configuration.jwt_secret, true, { algorithm: 'HS512', verify_jti: -> _ { validate_token(access_token) } }).first
        orga_data = data['organization']

        organization = Organization.find_or_create(id: orga_data['sub'], name: orga_data['name']) do |orga|
          orga.webhook_token = SecureRandom.hex
        end
        user = User.find_or_create(id: data['sub'], name: data['name'], organization_id: organization.id)

        {
          'box.user' => user,
          'box.organization' => organization,
          'box.admin' => data['ebicsbox']['role'].include?('admin'),
        }
      rescue JWT::DecodeError => ex
        Box.logger.info { "[OauthAuthentication] #{ex.message}" }
        {
          'box.user' => nil,
          'box.organization' => nil,
          'box.admin' => false,
        }
      end

      def validate_token(access_token)
        conn = Faraday.new URI(Box.configuration.oauth_server)
        conn.authorization :Bearer, access_token
        conn.head("oauth/token/info").success?
      end
    end
  end
end
