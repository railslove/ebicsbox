require 'epics/box/service'
require 'epics/box/management'
require 'epics/box/content'

module Epics
  module Box
    class Server < Grape::API
      mount Service
      mount Management
      mount Content
    end
  end
end
