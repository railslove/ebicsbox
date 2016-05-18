#
# This script should be loaded by all entrypoints as it sets up out app's namespace and handles
# our configuration. Moreover it ensures that the database is setup.
#

require 'logger'
require 'sequel'

require_relative './configuration'

# Setup box namespace
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

# Init database connection
DB = Sequel.connect(Box.configuration.database_url, max_connections: 10)

# Enable json extensions
Sequel.extension :pg_json
DB.extension :pg_json
