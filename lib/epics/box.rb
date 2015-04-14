require 'grape'
require 'sequel'
require 'cmxl'
require 'pg'
require 'httparty'
require 'json'
require 'nokogiri'
require 'epics'
require 'sepa_king'
require 'base64'

DB = Sequel.connect(ENV['DATABASE_URL'], max_connections: 10)
DB.extension(:connection_validator)

require "epics/box/version"
require "epics/box/server"
require "epics/box/worker"
require "epics/box/queue"
require "epics/box/queue/beanstalk"
require "epics/box/models/transaction"

module Epics
  module Box
    QUEUE  = Epics::Box::Queue::Beanstalk
    CLIENT = Epics::Client.new( File.open(ENV['KEYFILE']), ENV['PASSPHRASE'], ENV['EBICS_URL'], ENV['EBICS_HOST'], ENV['EBICS_USER'], ENV['EBICS_PARTNER'])
    # Your code goes here...
  end
end
