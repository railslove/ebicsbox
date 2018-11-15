if %w[development test].include?(ENV['ENVIRONMENT'])
  # Load environment from file
  require 'dotenv'
  Dotenv.load
end

# Load BL EBICS client when in BV environment
if ENV['EBICS_CLIENT'] == 'Blebics::Client'
  require 'blebics'
end

module Box
  class Configuration
    def app_url
      ENV['APP_URL'] || 'http://localhost:5000'
    end

    def database_url
      test? ?
        (ENV['TEST_DATABASE_URL'] || 'postgres://localhost/ebicsbox_test') :
        (ENV['DATABASE_URL'] || 'postgres://localhost/ebicsbox')
    end

    def hac_retrieval_interval
      120 # seconds
    end

    def activation_check_interval
      60 * 60 # seconds
    end

    def ebics_client
      (ENV['EBICS_CLIENT'] || 'Epics::Client').constantize
    end

    def db_passphrase
      ENV['PASSPHRASE']
    end

    def test?
      ENV['ENVIRONMENT'] == 'test'
    end

    def sandbox?
      ENV['SANDBOX'] == 'enabled'
    end

    def registrations_allowed?
      ENV['ALLOW_REGISTRATIONS'] == 'enabled'
    end

    def jwt_secret
      ENV['JWT_SECRET']
    end

    def oauth_server
      ENV['OAUTH_SERVER'] || 'http://localhost:3000'
    end

    def auth_provider
      if ENV['AUTH_SERVICE'] == 'static'
        require_relative '../box/middleware/static_authentication'
        Box::Middleware::StaticAuthentication
      else
        require_relative '../box/middleware/oauth_authentication'
        Box::Middleware::OauthAuthentication
      end
    end
  end
end
