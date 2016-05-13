require 'logger'
require 'sequel'

# Load configuration
require_relative './box/configuration'

module Epics
  module Box
    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.logger=(logger)
      @logger = logger
    end
  end
end

# Init database connection
DB = Sequel.connect(Epics::Box.configuration.database_url, max_connections: 10)

# Enable json extensions
Sequel.extension :pg_json
DB.extension :pg_json
