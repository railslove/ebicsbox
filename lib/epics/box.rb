lib = File.expand_path("../..", __FILE__)
$:.unshift(lib)

require 'dotenv'
Dotenv.load

require 'grape'
require 'grape-entity'
require 'sequel'
require 'cmxl'
require 'httparty'
require 'json'
require 'nokogiri'
require 'epics'
require 'sepa_king'
require 'sinatra'
require 'base64'

# Extensions to add swagger documentation methods
require 'ruby-swagger/grape/grape'
if RUBY_PLATFORM == 'java'
  require 'blebics'
end

require 'epics/box/configuration'

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

require "epics/box/server"
require "epics/box/worker"
require "epics/box/queue"
require "epics/box/models/account"
require "epics/box/models/organization"
require "epics/box/models/statement"
require "epics/box/models/subscriber"
require "epics/box/models/transaction"
require "epics/box/models/user"
