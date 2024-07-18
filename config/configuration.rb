# frozen_string_literal: true

env = ENV.fetch("RACK_ENV", "production")
if env.to_s != "production"
  # Load environment from file
  require "dotenv"
  Dotenv.load
end

module Box
  class ConfigurationError < StandardError; end

  class Configuration
    def app_url
      ENV["APP_URL"] || "http://localhost:5000"
    end

    def database_url
      return ENV["TEST_DATABASE_URL"] || "postgres://localhost/ebicsbox_test" if test?

      ENV["DATABASE_URL"] || "postgres://localhost/ebicsbox"
    end

    def hac_retrieval_interval
      120 # seconds
    end

    def ebics_client
      (ENV["EBICS_CLIENT"] || "Epics::Client").constantize
    end

    def db_passphrase
      ENV.fetch("PASSPHRASE")
    rescue KeyError
      raise ConfigurationError, "PASSPHRASE missing"
    end

    def test?
      ENV["RACK_ENV"] == "test"
    end

    def sandbox?
      ENV["SANDBOX"] == "enabled"
    end

    def ui_initial_setup?
      ENV["UI_INITIAL_SETUP"] == "enabled"
    end

    def registrations_allowed?
      ENV["ALLOW_REGISTRATIONS"] == "enabled"
    end

    def jwt_secret
      ENV.fetch("JWT_SECRET")
    rescue KeyError
      raise ConfigurationError, "JWT_SECRET missing"
    end

    def oauth_server
      ENV["OAUTH_SERVER"] || "http://localhost:3000"
    end

    def static_auth?
      ENV["AUTH_SERVICE"] == "static"
    end

    def auth_provider
      if static_auth?
        require_relative "../box/middleware/static_authentication"
        Box::Middleware::StaticAuthentication
      else
        require_relative "../box/middleware/oauth_authentication"
        Box::Middleware::OauthAuthentication
      end
    end

    def valid?
      # try fetching all env vars required for a smooth operation
      db_passphrase

      jwt_secret unless static_auth?
    end

    def webhook_encryption_key
      ENV["WEBHOOK_ENCRYPTION_KEY"]
    end

    def encrypt_webhooks?
      webhook_encryption_key != nil
    end
  end
end
