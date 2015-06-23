module Epics
  module Box
    class Configuration
      def database_url
        ENV['DATABASE_URL'] || 'postgres://localhost/ebicsbox_test'
      end

      def beanstalkd_url
        ENV['BEANSTALKD_URL'] || 'localhost:11300'
      end

      def hac_retrieval_interval
        120 # seconds
      end
    end
  end
end
