module Epics
  module Box
    class Configuration
      def database_url
        test? ?
          (ENV['TEST_DATABASE_URL'] || 'postgres://localhost/ebicsbox_test') :
          (ENV['DATABASE_URL'] || 'postgres://localhost/ebicsbox')
      end

      def beanstalkd_url
        ENV['BEANSTALKD_URL'] || 'localhost:11300'
      end

      def hac_retrieval_interval
        120 # seconds
      end

      def activation_check_interval
        60 * 60 * 24 # seconds
      end

      def secret_token
        if token = ENV['SECRET_TOKEN']
          token
        else
          raise 'Please set a secret token'
        end
      end

      def db_passphrase
        ENV['PASSPHRASE']
      end

      def test?
        !ENV['TEST'].empty?
      end
    end
  end
end
