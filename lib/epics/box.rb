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

require 'epics/box/version'
require 'epics/box/configuration'

module Epics
  module Box
    # CLIENT = Epics::Client.new( File.open(ENV['KEYFILE']), ENV['PASSPHRASE'], ENV['EBICS_URL'], ENV['EBICS_HOST'], ENV['EBICS_USER'], ENV['EBICS_PARTNER'])
    # Your code goes here...

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end

# Init database connection
DB = Sequel.connect(Epics::Box.configuration.database_url, max_connections: 10)

require "epics/box/server"
require "epics/box/admin"
require "epics/box/worker"
require "epics/box/queue"
require "epics/box/models/account"
require "epics/box/models/statement"
require "epics/box/models/transaction"
require "epics/box/presenters/statement_presenter"
