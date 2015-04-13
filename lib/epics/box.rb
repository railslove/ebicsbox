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

require "epics/box/version"
require "epics/box/server"
require "epics/box/worker"
require "epics/box/queue"
require "epics/box/queue/beanstalk"

module Epics
  module Box

    QUEUE  = Epics::Box::Queue::Beanstalk
    DB     = Sequel.connect("postgres://localhost/ebicsbox", max_connections: 10, logger: Logger.new(STDOUT))
    CLIENT = Epics::Client.new( File.open(ENV['KEYFILE']), ENV['PASSPHRASE'], ENV['EBICS_URL'], ENV['EBICS_HOST'], ENV['EBICS_USER'], ENV['EBICS_PARTNER'])
    # Your code goes here...
  end
end
