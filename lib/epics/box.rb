lib = File.expand_path("../..", __FILE__)
$:.unshift(lib)

# Load configuration
require 'epics/box/configuration'

# Load dependencies
# TODO: Remove them here and load where really used!
require 'grape'
require 'grape-entity'
require 'sequel'
require 'cmxl'
require 'faraday'
require 'json'
require 'nokogiri'
require ENV['EBICS_CLIENT'] == 'Blebics::Client' ? 'blebics' : 'epics'
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

Ebics = Epics

# Enable json extensions
Sequel.extension :pg_json
DB.extension :pg_json

require "epics/box/server"
require "epics/box/worker"
require "epics/box/queue"
require "epics/box/models/account"
require "epics/box/models/organization"
require "epics/box/models/statement"
require "epics/box/models/subscriber"
require "epics/box/models/transaction"
require "epics/box/models/user"
