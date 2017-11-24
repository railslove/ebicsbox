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
    @logger ||= Logger.new(STDOUT).tap do |logger|
      logger.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::INFO
    end
  end

  def self.logger=(logger)
    @logger = logger
  end
end

# Init database connection
DB = Sequel.connect(Box.configuration.database_url, max_connections: 10)

# enable histoic symbol splitting to create qualified and/or aliased identifiers
# https://github.com/jeremyevans/sequel/blob/master/doc/release_notes/5.0.0.txt#L18
# ToDo: update code to support default and disable split_symbols
Sequel.split_symbols = true
# Enable json extensions
Sequel::Model.plugin :timestamps, update_on_create: true
Sequel.extension :pg_json
DB.extension :pg_json
