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
require 'sinatra'
require 'base64'

DB = Sequel.connect(ENV['DATABASE_URL'], max_connections: 10)

require "epics/box/version"
require "epics/box/server"
require "epics/box/admin"
require "epics/box/worker"
require "epics/box/queue"
require "epics/box/queue/beanstalk"
require "epics/box/models/account"
require "epics/box/models/statement"
require "epics/box/models/transaction"
require "epics/box/presenters/statement_presenter"

Beaneater.configure do |config|
  config.job_parser          = lambda { |body| JSON.parse(body, symbolize_names: true) }
end

module Epics
  module Box
    DEBIT_MAPPING = {
      "CORE" => :CDD,
      "COR1" => :CD1,
      "B2B" =>  :CDB,
    }

    QUEUE  = Epics::Box::Queue::Beanstalk
    # CLIENT = Epics::Client.new( File.open(ENV['KEYFILE']), ENV['PASSPHRASE'], ENV['EBICS_URL'], ENV['EBICS_HOST'], ENV['EBICS_USER'], ENV['EBICS_PARTNER'])
    # Your code goes here...
  end
end
