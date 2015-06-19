module Epics
  module Box
    class Configuration
      def database_url
        ENV['DATABASE_URL'] || 'postgres://localhost/ebicsbox_test'
      end
    end
  end
end
