# Load configuration
require_relative './box/configuration'

# Load dependencies
# TODO: Remove them here and load where really used!
require 'grape'
require 'grape-entity'
require 'sequel'
require 'cmxl'
require 'camt_parser'
require 'faraday'
require 'json'
require 'nokogiri'
require 'epics'
require 'sepa_king'
require 'base64'

# Extensions to add swagger documentation methods
require 'ruby-swagger/grape/grape'

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

require_relative "./box/server"
require_relative "./box/worker"
require_relative "./box/queue"
require_relative "./box/models/account"
require_relative "./box/models/organization"
require_relative "./box/models/statement"
require_relative "./box/models/subscriber"
require_relative "./box/models/transaction"
require_relative "./box/models/user"
