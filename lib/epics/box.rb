require 'grape'
require 'redis'
require 'httparty'
require 'json'
require 'nokogiri'
require 'base64'

require "epics/box/version"
require "epics/box/server"
require "epics/box/worker"
require "epics/box/queue"
require "epics/box/queue/beanstalk"

module Epics
  module Box

    QUEUE = Epics::Box::Queue::Beanstalk
    # Your code goes here...
  end
end
