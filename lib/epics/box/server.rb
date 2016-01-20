require_relative './registration'
require_relative './service'
require_relative './management'
require_relative './content'

module Epics
  module Box
    class Server < Grape::API
      mount Service
      mount Registration
      mount Management
      mount Content
    end
  end
end
