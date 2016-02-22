# Load BL EBICS client when in BV environment
module Epics
  module Box
    class Configuration
      def app_url
        ENV['APP_URL'] || 'http://localhost:5000'
      end

      def database_url
        test? ?
          (ENV['TEST_DATABASE_URL'] || 'jdbc:postgres://localhost/ebicsbox_test') :
          (ENV['DATABASE_URL'] || 'jdbc:postgres://localhost/ebicsbox')
      end

      def beanstalkd_url
        (ENV['BEANSTALKD_URL'] || 'localhost:11300').gsub('beanstalkd://','').gsub('/','')
      end

      def hac_retrieval_interval
        120 # seconds
      end

      def activation_check_interval
        60 * 60 # seconds
      end

      def secret_token
        if token = ENV['SECRET_TOKEN']
          token
        else
          raise 'Please set a secret token'
        end
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

      def registrations_allowed?
        ENV['ALLOW_REGISTRATIONS'] == 'enabled'
      end
    end
  end
end
