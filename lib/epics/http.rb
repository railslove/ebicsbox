require 'grape'
require 'redis'
require 'httparty'
require 'json'
require 'nokogiri'
require 'base64'

require "epics/http/version"
require "epics/http/server"
require "epics/http/worker"
require "epics/http/queue"
require "epics/http/queue/beanstalk"

module Epics
  module Http

    QUEUE = Epics::Http::Queue::Beanstalk
    # Your code goes here...
  end
end
