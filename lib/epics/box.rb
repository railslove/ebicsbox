require 'grape'
require 'grape-entity'
require 'sequel'
require 'cmxl'
require 'pg'
require 'httparty'
require 'json'
require 'nokogiri'
require 'epics'
require 'sepa_king'
require 'base64'

require 'epics/box/version'
require 'epics/box/configuration'

module Epics
  module Box
    DEBIT_MAPPING = {
      "CORE" => :CDD,
      "COR1" => :CD1,
      "B2B" =>  :CDB,
    }

    # QUEUE  = Epics::Box::Queue::Beanstalk
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
DB.extension(:connection_validator)

require "epics/box/server"
require "epics/box/worker"
require "epics/box/queue"
require "epics/box/queue/beanstalk"
require "epics/box/models/account"
require "epics/box/models/statement"
require "epics/box/models/transaction"
require "epics/box/presenters/statement_presenter"
