require 'grape'

require_relative '../box'
require_relative './registration'
require_relative './service'
require_relative './management'
require_relative './content'

module Epics
  module Box
    class Server < Grape::API
      mount Service
      mount Management
      mount Content
      mount Registration
    end
  end
end
